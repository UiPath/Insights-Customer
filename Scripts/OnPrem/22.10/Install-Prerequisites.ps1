<#
  .SYNOPSIS
  Installs all required software for insights

  .DESCRIPTION
  The Install-Prerequisites.ps1 script installs all required software for insights.

  .INPUTS
  None. You cannot pipe objects to Install-Prerequisites.ps1.

  .OUTPUTS
  None. Install-Prerequisites.ps1 does not generate any output.

  .EXAMPLE
  PS> .\Install-Prerequisites.ps1
#>

# UiPath Insights Prerequisites Installation Script

function Test-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal( $identity )
    return $principal.IsInRole( [System.Security.Principal.WindowsBuiltInRole]::Administrator )
}

if (-not(Test-Admin)) {
    Write-Output "User is not running with administrative rights.`nPlease open a PowerShell console as administrator and try again."
    Exit 2
}

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"

$ScriptVersion = "1.0"
$sLogName = "Install-InsightsPrerequisites.log"
$sLogFile = Join-Path -Path $PSScriptRoot -ChildPath $sLogName

Start-Transcript -path $sLogFile

Write-Output ""
Write-Output "Running UiPath Insights Prerequisites Installation Script v$ScriptVersion"
Write-Output ""
Write-Output "***************************************************************************************************"

Write-Output ""
Write-Output "Enabling IIS-WebServerRole..."
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -all -NoRestart

$HostingBundleInstallerFilePath = "$env:tmp/dotnet-hosting-6.0.15-win.exe"
if (-Not(Test-Path $HostingBundleInstallerFilePath -PathType Leaf)) {
    Write-Output ""
    Write-Output "Downloading Dotnet Hosting Bundle..."
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://download.visualstudio.microsoft.com/download/pr/e38901ef-e9ac-4331-a6aa-f2aec3b1754b/6d695fa51a4960393edaf725ce970a86/dotnet-hosting-6.0.15-win.exe", $HostingBundleInstallerFilePath )
}

Write-Output "Installing Dotnet Hosting Bundle..."
Start-Process "$HostingBundleInstallerFilePath" -ArgumentList "/install /quiet /norestart" -Wait -NoNewWindow -PassThru | Out-Null

Write-Output ""
Write-Output "Restarting IIS..."
net stop was /y ; net start w3svc

Stop-Transcript
