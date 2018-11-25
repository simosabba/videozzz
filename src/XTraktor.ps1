
param(
    [Parameter(Mandatory=$true)]
    [string]$InputDirectory,
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    [Switch]$Overwrite)

$mediaInfoCliPath = "C:\Users\Simone\source\repos\videozzz\src\mediainfo_cli\MediaInfo.exe"

function Create-MediaInfoRecord
{
    param (
        $MediaDataRecord
    )

    $GeneralTrack = $MediaDataRecord.MediaInfo.MediaInfo.media.track | Where-Object { $_.type -eq "general" }
    $VideoTrack = $MediaDataRecord.MediaInfo.MediaInfo.media.track | Where-Object { $_.type -eq "Video" }
    $AudioTrack = $MediaDataRecord.MediaInfo.MediaInfo.media.track | Where-Object { $_.type -eq "Audio" }
    
    $Record = New-Object PSObject
    $Record | Add-Member NoteProperty InputFile $MediaDataRecord.InputFile.FullName
    
    #GENERAL
    $Record | Add-Member NoteProperty General_Format $GeneralTrack.Format
    $Record | Add-Member NoteProperty General_FileSize $GeneralTrack.FileSize
    $Record | Add-Member NoteProperty General_Duration $GeneralTrack.Duration
    $Record | Add-Member NoteProperty General_OverallBitRate $GeneralTrack.OverallBitRate

    #VIDEO
    $Record | Add-Member NoteProperty Video_Format $VideoTrack.Format
    $Record | Add-Member NoteProperty Video_Format_Profile $VideoTrack.Format_Profile
    $Record | Add-Member NoteProperty Video_Format_Level $VideoTrack.Format_Level
    $Record | Add-Member NoteProperty Video_Format_Settings_CABAC $VideoTrack.Format_Settings_CABAC
    $Record | Add-Member NoteProperty Video_Format_Settings_RefFrames $VideoTrack.Format_Settings_RefFrames
    $Record | Add-Member NoteProperty Video_Width $VideoTrack.Width
    $Record | Add-Member NoteProperty Video_Height $VideoTrack.Height
    $Record | Add-Member NoteProperty Video_FrameRate $VideoTrack.FrameRate
    $Record | Add-Member NoteProperty Video_ColorSpace $VideoTrack.ColorSpace
    $Record | Add-Member NoteProperty Video_ChromaSubsampling $VideoTrack.ChromaSubsampling
    $Record | Add-Member NoteProperty Video_BitDepth $VideoTrack.BitDepth

    #AUDIO
    $Record | Add-Member NoteProperty Audio_Format $AudioTrack.Format
    $Record | Add-Member NoteProperty Audio_BitRate $AudioTrack.BitRate
    $Record | Add-Member NoteProperty Audio_Channels $AudioTrack.Channels
    $Record | Add-Member NoteProperty Audio_SamplingRate $AudioTrack.SamplingRate

    return $Record
}

function Export-MediaInfo
{
    param(
        $MediaData,
        $OutputFile
    )

    $Rows = $MediaData | ForEach-Object { Create-MediaInfoRecord -MediaDataRecord $_ }
    $Rows | Export-Csv $OutputFile -Delimiter ';' -NoClobber -NoTypeInformation
}

function XTrakt-File
{
    param(
        [System.IO.FileInfo]$File
    )

    Write-Host ("Processing " + $File.FullName)
    $MediaInfoArgs = @('--Output=XML', $File.FullName)
    $MediaInfoOut = [Xml](& $mediaInfoCliPath $MediaInfoArgs | Out-String)
    
    $OutData = New-Object PSObject
    $OutData | Add-Member NoteProperty InputFile $File
    $OutData | Add-Member NoteProperty MediaInfo $MediaInfoOut
    return $OutData
}

function  XTrakt-Directory {
    param (
        $InputDirectory,
        $OutputFile
    )
   
    Write-Host "STARTED -> Processing directory $InputDirectory"
    $Files = Get-ChildItem $InputDirectory -Recurse -File

    $MediaData = @()
    $Files | ForEach-Object{ $MediaData += (XTrakt-File -File $_) }

    Export-MediaInfo -MediaData $MediaData -OutputFile $OutputFile
    Write-Host "COMPLETED -> Processing directory $InputDirectory"
}

### MAIN ###

if ([IO.File]::Exists($OutputFile) -and !$Overwrite)
{
    Write-Host "File $OutputFile already exists."
    Write-Host "Overwrite? (y|n)"
    $Key = [Console]::ReadKey()
    if ($Key.KeyChar.ToString().ToLower() -ne "y")
        { exit }
}

XTrakt-Directory -InputDirectory $InputDirectory -OutputFile $OutputFile

