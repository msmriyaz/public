$target_aspnetcore_version = "3.1.29"

Write-Host "This script will update the aspnetcore runtime from 3.1.* to $target_aspnetcore_version" -ForegroundColor Cyan

# Make a directory called Temp in C:\ drive, only if it doesn't exist
if (!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp"
}
$downloadPath = "C:\Temp\"

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/download/3.8.4/PSAppDeployToolkit_v3.8.4.zip" -OutFile $($downloadPath + "PSAppDeployToolkit_v3.8.4.zip")
$ProgressPreference = 'Continue'

# Run Unblock-File command on the downloaded file as administrator
Unblock-File -Path $($downloadPath + "PSAppDeployToolkit_v3.8.4.zip")

# Extract the contents of the zip file to C:\Temp directory
Expand-Archive -Path $($downloadPath + "PSAppDeployToolkit_v3.8.4.zip") -DestinationPath $downloadPath -Force

# Make a folder ASPNETCoreRuntime31 inside C:\Temp directory
if (!(Test-Path -Path "C:\Temp\ASPNETCoreRuntime31")) {
    New-Item -ItemType Directory -Path "C:\Temp\ASPNETCoreRuntime31"
}

# Copy item from C:\temp\Toolkit\AppDeployToolkit to C:\Temp\ASPNETCoreRuntime31
Copy-Item -Path "C:\Temp\Toolkit\AppDeployToolkit" -Destination "C:\Temp\ASPNETCoreRuntime31" -Recurse -Force

# Copy item from C:\temp\Toolkit\Files to C:\Temp\ASPNETCoreRuntime31
Copy-Item -Path "C:\Temp\Toolkit\Files" -Destination "C:\Temp\ASPNETCoreRuntime31" -Recurse -Force

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

# Pre-run to warn the user of removing the current version before installing the new version
$SFPath31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include AspNetCoreSharedFrameworkBundle*.exe -Recurse -ErrorAction SilentlyContinue
ForEach ($SF in $SFPath31){Write-Host -f Yellow "Found $($SF.FullName), admin to choose removal."}

$RuntimeHB31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include WindowsServerHostingBundle.exe -Recurse -ErrorAction SilentlyContinue
ForEach ($Runtime in $RuntimeHB31){Write-Host -f Yellow  "Found $($Runtime.FullName), admin to choose removal."}

$RuntimePath31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include dotnet-runtime-3.1.*win*.exe -Recurse -ErrorAction SilentlyContinue
ForEach ($Runtime in $RuntimePath31){Write-Host -f Yellow  "Found $($Runtime.FullName), admin to choose removal."}

# Ask the user if they want to remove? if yes, remove
$remove = Read-Host -Prompt "Do you want to remove now? (y/n)"
if ($remove -eq "y") {
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
}

# Ask whether you want to continue installing or not
$continue = Read-Host -Prompt "Do you want to continue installing? (y/n)"
if ($continue -eq "y") {
    # 1
    # Download the ASP.NET Core Runtime 3.1.<latest> On Windows, we recommend installing the Hosting Bundle, which includes the .NET Runtime and IIS support to C:\Temp\ASPNETCoreRuntime31 directory
    $currentDownloadPath = "C:\Temp\ASPNETCoreRuntime31\Files\"
    $downloadLink = "https://download.visualstudio.microsoft.com/download/pr/d7924d3c-977f-4130-bcf3-5851881e90c4/9f8715d4e5824730da1d78ace9baeb9e/dotnet-hosting-$target_aspnetcore_version-win.exe"

    Write-Host "Downloading ASP.NET Core Hosting Bundle, which includes the .NET Runtime and IIS support $target_aspnetcore_version installer to C:\Temp\ASPNETCoreRuntime31\Files directory"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadLink -OutFile $($currentDownloadPath + "dotnet-hosting-$target_aspnetcore_version-win.exe")
    $ProgressPreference = 'Continue'

    Write-Host "Download complete"
    Write-Host "Running the installer now"
    # upgrade the existing aspnetcore runtime
    Start-Process -FilePath $($currentDownloadPath + "dotnet-hosting-$target_aspnetcore_version-win.exe") -ArgumentList "/install /quiet /norestart" -Wait

    # 2
    # Download the ASP.NET Core Runtime 3.1.<latest> On Windows, we recommend installing the Hosting Bundle, which includes the .NET Runtime and IIS support to C:\Temp\ASPNETCoreRuntime31 directory
    $currentDownloadPath = "C:\Temp\ASPNETCoreRuntime31\Files\"
    $downloadLink = "https://download.visualstudio.microsoft.com/download/pr/ad97751d-b5b0-4646-91db-74705aceac64/c89bcdeb4a10db4768fae62fec33fb42/aspnetcore-runtime-$target_aspnetcore_version-win-x64.exe"

    Write-Host "Downloading ASP.NET Core runtime $target_aspnetcore_version installer to C:\Temp\ASPNETCoreRuntime31\Files directory"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadLink -OutFile $($currentDownloadPath + "aspnetcore-runtime-$target_aspnetcore_version-win-x64.exe")
    $ProgressPreference = 'Continue'

    Write-Host "Download complete"
    Write-Host "Running the installer now"
    # upgrade the existing aspnetcore runtime
    Start-Process -FilePath $($currentDownloadPath + "aspnetcore-runtime-$target_aspnetcore_version-win-x64.exe") -ArgumentList "/install /quiet /norestart" -Wait

    # reload environment variables
    write-host "Reloading environment variables"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    dotnet --list-runtimes

    Remove-Item $($currentDownloadPath + "dotnet-hosting-$target_aspnetcore_version-win.exe")
    Remove-Item $($currentDownloadPath + "aspnetcore-runtime-$target_aspnetcore_version-win-x64.exe")

    # Pre-run to warn the user of removing the current version before installing the new version
    $SFPath31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include AspNetCoreSharedFrameworkBundle*.exe -Recurse -ErrorAction SilentlyContinue
    ForEach ($SF in $SFPath31){Write-Host -f Green "Installed $($SF.FullName)"}

    $RuntimeHB31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include WindowsServerHostingBundle.exe -Recurse -ErrorAction SilentlyContinue
    ForEach ($Runtime in $RuntimeHB31){Write-Host -f Green  "Installed $($Runtime.FullName)"}

    $RuntimePath31 = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include dotnet-runtime-3.1.*win*.exe -Recurse -ErrorAction SilentlyContinue
    ForEach ($Runtime in $RuntimePath31){Write-Host -f Green  "Installed $($Runtime.FullName)"}

    Read-Host -Prompt "Press any key to continue..."
    Write-Log -Message "Installation of $installTitle completed."
}