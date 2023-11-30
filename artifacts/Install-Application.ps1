<#
.SYNOPSIS
    Installs Application
.DESCRIPTION
    Installs an application for Azure Image Builder
.PARAMETER ManifestFile
    The path to the manifest file for the application
.NOTES
    This script is a customizer for Azure Image Builder service.
.LINK
    https://aka.ms/installazurecliwindowsx64
.EXAMPLE
    Install-Application -ManifestFile 'manifest-app.json' -Verbose
#>

[CmdletBinding()]
param(
    [string]$ManifestFile
)

# Read the manifest file
try {
    $Manifest = Get-Content $ManifestFile | ConvertFrom-Json
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error "Error reading the manifest file - $ErrorMessage"
}

# Common variables
[string]$UAMI = $Manifest.uami
[string]$PackagePath = $Manifest.packagePath
[string]$PackageLocalPath = $Manifest.packageLocalPath
[string]$AppName = $Manifest.appName
[string]$InstallationPath = $Manifest.installationPath
[string]$AppType = $Manifest.appType
[string]$Arguments = $Manifest.arguments
[bool]$Zipped = $Manifest.zipped
[string]$ArchiveLocalPath = $Manifest.archiveLocalPath

#region Common functions
$logFile = "C:\ImageBuilder\" + (Get-Date -Format 'yyyyMMdd') + '_image-build.log'
function Write-Log {
    [CmdletBinding()]
    param(
        [string]$message
    )
    process {
        Write-Output "$(Get-Date -Format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
    }
}
#endregion

#region Sign-in to Azure with AzCopy using UAMI
try {
    Start-Process -FilePath 'C:\ImageBuilder\azcopy.exe' -Wait -ErrorAction Stop -ArgumentList 'login', '--identity', '--identity-resource-id', $UAMI
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Log "Error signing in using UAMI - $ErrorMessage"
}
#endregion

#region Download and Extract app archive
if ($Zipped) {
    try {
        # AZCopy to download the archive file and extract to the ImageBuilder directory
        C:\ImageBuilder\azcopy.exe copy $PackagePath $ArchiveLocalPath
        Write-Log "$AppName downloaded"
        Expand-Archive $ArchiveLocalPath 'c:\ImageBuilder'
        Write-Log "$AppName extracted"
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Log "Error extracting $AppName - $ErrorMessage"
    }
}
else {
    try {
        # AZCopy to download the archive file and save to the ImageBuilder directory
        C:\ImageBuilder\azcopy.exe copy $PackagePath $PackageLocalPath
        Write-Log "$AppName downloaded"
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Log "Error downloading $AppName - $ErrorMessage"
    }
}
#endregion

#region Install app
$ProgressPreference = 'SilentlyContinue'
if ($AppType -eq 'msi') {
    try {
        Start-Process -FilePath msiexec.exe -Wait -ErrorAction Stop -ArgumentList $Arguments
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Log "Error installing $AppName - $ErrorMessage"
    }
}
elseif ($AppType -eq 'appx') {
    try {
        Add-AppxPackage -AppInstallerFile $PackageLocalPath
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Log "Error installing $AppName - $ErrorMessage"
    }
}
elseif ($AppType -eq 'exe') {
    try {
        Start-Process -FilePath $PackageLocalPath -Wait -ErrorAction Stop -ArgumentList $Arguments
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Log "Error installing $AppName - $ErrorMessage"
    }
}
else {
    Write-Log "Error installing $AppName - Unsupported app type"
}
#endregion

#region Validate the installation path
try {
    if (Test-Path $InstallationPath) {
        Write-Log "$AppName installed"
    }
    else {
        Write-Log "Error locating the $AppName executable"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Log "Error installing $AppName - $ErrorMessage"
}
$ProgressPreference = 'Continue'
#endregion

