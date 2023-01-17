# 2022-12 Cumulative Update for .NET Framework 3.5 and 4.8 for Windows Server 2019 for x64 (KB5020874)
$target_patch = "KB5020874"
$targetFile = "windows10.0-kb5020874-x64-ndp48_01a8a26523a2f43e14715e7d33434b094d529233.msu"
$downloadLink = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2022/10/$targetFile"

Write-Host "This script will update the os to $target_patch" -ForegroundColor Cyan

# Make a directory called Temp in C:\ drive, only if it doesn't exist
if (!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp"
}
$currentDownloadPath = "C:\Temp\"

Write-Host "Downloading $downloadLink - $target_patch to $currentDownloadPath\$targetFile"
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $downloadLink -OutFile $($currentDownloadPath + "\$targetFile")
$ProgressPreference = 'Continue'

# run the downloaded .msu file silently
Write-Host "Installing $target_patch"

# powershell execute start /wait wusa.exe %~dp0Win7AndW2K8R2-KB3134760-x64.msu /quiet /norestart
$msu = $($currentDownloadPath + "$targetFile")
#$arguments = "/quiet /norestart"
$arguments = "$msu /quiet /norestart /log:$currentDownloadPath" + "KB5020874.evtx"
$process = Start-Process -FilePath "wusa.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
$exitCode = $process.ExitCode
Write-Host "Exit code: $exitCode"