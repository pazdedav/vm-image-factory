<#
.SYNOPSIS
    Downloads application manifests
.DESCRIPTION
    Downloads the manifest files for Azure Image Builder
.NOTES
    This script is a customizer for Azure Image Builder service.
.LINK
    https://aka.ms/installazurecliwindowsx64
.EXAMPLE
    Get-Manifests -Verbose
#>
[CmdletBinding()]

# Common variables
[string]$sourcePath = 'https://imgfactoryassets.blob.core.windows.net/scripts/*'
[string]$destinationPath = 'C:\ImageBuilder'
[string]$UAMI = '/subscriptions/xxxxx-xxxx-xxxxxx-xxxxx-xxxxx/resourcegroups/imagefactory-prod-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/imagefactory-prod-uai'

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
    c:\ImageBuilder\azcopy.exe login --identity --identity-resource-id $UAMI
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Log "Error signing in using UAMI - $ErrorMessage"
}
#endregion

#region Download manifests
try {
    # AZCopy to download the application manifests to the ImageBuilder directory
    C:\ImageBuilder\azcopy.exe copy $sourcePath $destinationPath --include-pattern 'manifest*.json'
    Write-Log "Manifests were downloaded"
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Log "Error extracting $AppName - $ErrorMessage"
}
#endregion

