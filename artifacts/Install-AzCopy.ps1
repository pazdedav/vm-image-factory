<#
.SYNOPSIS
    Installs AzCopy
.DESCRIPTION
    Installs AzCopy tool for Azure Image Builder
.NOTES
    This script is a customizer for Azure Image Builder service. It doesn't support parameters.
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Install-AzCopy -Verbose
#>

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

#region Create ImageBuilder directory if it doesn't exist
$Folder = 'c:\ImageBuilder'
if (Test-Path -Path $Folder) {
    Write-Log "ImageBuilder directory already exists"
}
else {
    New-Item -Type Directory -Path 'c:\' -Name ImageBuilder
    Write-Log "ImageBuilder directory created"
}
#endregion

#region Download and extract AZCopy
try {
    Invoke-WebRequest -uri 'https://aka.ms/downloadazcopy-v10-windows' -OutFile 'c:\ImageBuilder\azcopy.zip'
    Expand-Archive 'c:\ImageBuilder\azcopy.zip' 'c:\ImageBuilder'
    Copy-Item -Path 'C:\ImageBuilder\azcopy_windows_amd64_*\azcopy.exe' -Destination 'c:\ImageBuilder'
    Write-Log "Az CLI downloaded"
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Log "Error downloading Az CLI: $ErrorMessage"
}
#endregion