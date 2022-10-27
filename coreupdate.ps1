# Make a directory called Temp in C:\ drive, only if it doesn't exist
if (!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp"
}
$downloadPath = "C:\Temp\"

# Download link "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/download/3.8.4/PSAppDeployToolkit_v3.8.4.zip" to C:\Temp directory
Invoke-WebRequest -Uri "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/download/3.8.4/PSAppDeployToolkit_v3.8.4.zip" -OutFile $($downloadPath + "PSAppDeployToolkit_v3.8.4.zip")

# Run Unblock-File command on the downloaded file as administrator
Unblock-File -Path $($downloadPath + "PSAppDeployToolkit_v3.8.4.zip")

# Extract the contents of the zip file to C:\Temp directory
Expand-Archive -Path $($downloadPath + "PSAppDeployToolkit_v3.8.4.zip") -DestinationPath $downloadPath

# Make a folder ASPNETCoreRuntime31 inside C:\Temp directory
if (!(Test-Path -Path "C:\Temp\ASPNETCoreRuntime31")) {
    New-Item -ItemType Directory -Path "C:\Temp\ASPNETCoreRuntime31"
}

# Copy item from C:\temp\Toolkit\AppDeployToolkit to C:\Temp\ASPNETCoreRuntime31
Copy-Item -Path "C:\Temp\Toolkit\AppDeployToolkit" -Destination "C:\Temp\ASPNETCoreRuntime31" -Recurse

# Copy item from C:\temp\Toolkit\Files to C:\Temp\ASPNETCoreRuntime31
Copy-Item -Path "C:\Temp\Toolkit\Files" -Destination "C:\Temp\ASPNETCoreRuntime31" -Recurse

$scriptDirectory = "C:\temp\ASPNETCoreRuntime31"
## Variables: Environment
If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
    [string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
## Dot source the required App Deploy Toolkit Functions
Try {
    [string]$moduleAppDeployToolkitMain = "C:\temp\ASPNETCoreRuntime31\AppDeployToolkit\AppDeployToolkitMain.ps1"
    If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
    If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
}
Catch {
    If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
    Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
    ## Exit the script, returning the exit code to SCCM
    If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
}

# Remove Any Existing Version of ASP.NET Core Runtime Shared Framework 3.1
$SFPath31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include AspNetCoreSharedFrameworkBundle*.exe -Recurse -ErrorAction SilentlyContinue
ForEach ($SF in $SFPath31)
{
    Write-Log -Message "Found $($SF.FullName), now attempting to uninstall $installTitle."
    Execute-Process -Path "$SF" -Parameters "/uninstall /quiet /norestart /log C:\Windows\Logs\Software\ASPNETSharedFramework31-Uninstall.log" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

$RuntimeHB31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include WindowsServerHostingBundle.exe -Recurse -ErrorAction SilentlyContinue
ForEach ($Runtime in $RuntimeHB31)
{
    Write-Log -Message "Found $($Runtime.FullName), now attempting to uninstall $installTitle."
    Execute-Process -Path "$Runtime" -Parameters "/uninstall /quiet /norestart /log C:\Windows\Logs\Software\ASPNETCoreHostingBundle31-Uninstall.log" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

$RuntimePath31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include dotnet-runtime-3.1.*win*.exe -Recurse -ErrorAction SilentlyContinue
ForEach ($Runtime in $RuntimePath31)
{
    Write-Log -Message "Found $($Runtime.FullName), now attempting to uninstall $installTitle."
    Execute-Process -Path "$Runtime" -Parameters "/uninstall /quiet /norestart /log C:\Windows\Logs\Software\ASPNETCoreRuntime31-Uninstall.log" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# Download the ASP.NET Core Runtime 3.1.0 installer to C:\Temp\ASPNETCoreRuntime31 directory
$currentDownloadPath = "C:\Temp\ASPNETCoreRuntime31\Files\"
$downloadLink = "https://download.visualstudio.microsoft.com/download/pr/c6eac4d8-45f2-442d-a43d-79b30249cef8/35ffdb7ea4dc51f11705732a3a1d1d4c/dotnet-sdk-3.1.423-win-x64.exe"

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $downloadLink -OutFile $($currentDownloadPath + "dotnet-sdk-3.1.423-win-x64.exe")
$ProgressPreference = 'Continue'

# upgrade the existing aspnetcore runtime
Start-Process -FilePath $($currentDownloadPath + "dotnet-sdk-3.1.423-win-x64.exe") -ArgumentList "/install /quiet /norestart" -Wait

# reload environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
dotnet --list-runtimes

Remove-Item $($currentDownloadPath + "dotnet-sdk-3.1.423-win-x64.exe")
Read-Host -Prompt "Press any key to continue..."