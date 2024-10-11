<#
  .SYNOPSIS
  Performs Looker Initialization on the designated remote Linux VM

  .DESCRIPTION
  The Deploy-Looker.ps1 script updates the registry with new data generated during
  the past month and generates a report.

  .PARAMETER ComputerName
  Specifies the hostname of the remote Linux VM.

  .PARAMETER Port
  (Optional) Specifies the port of the remote Linux VM, if this parameter is not set,
  the script will use 22 as default port.

  .PARAMETER Username
  Specifies the user name to login to the remote Linux VM.

  .PARAMETER Password
  (Optional) Specifies the password to login to the remote Linux VM.
  Note: if use SSH public key to authenticate, this parameter is used to enter
  passphrase.

  .PARAMETER KeyfilePath
  (Optional) Specifies the path to the SSH public key.

  .PARAMETER SudoPass
  (Optional) Specifies the password for sudo in the remote Linux VM.

  .PARAMETER LookerZipFilePath
  Specifies the path to the Looker Zip File generated by LookerPreInstallationTool.

  .PARAMETER LookerImageFilePath
  (Optional) Specifies the path to the Looker Image File for offline initialization.

  .PARAMETER LookerImageVersionTag
  (Optional) Specifies the looker image tag for dev/testing purpose.

  .PARAMETER OfflineBundleFilePath
  (Optional) Specifies the path to the offline bundle File for offline initialization.

  .PARAMETER BypassSystemCheck
  (Optional) Specifies whether bypass system check for linux VM.

  .PARAMETER AutoUpdateFingerprint
  (Optional) Specifies whether automatically update fingerprint when setup SSH connection.

  .INPUTS
  None. You cannot pipe objects to Deploy-Looker.ps1.

  .OUTPUTS
  None. Deploy-Looker.ps1 does not generate any output.

  .EXAMPLE
  PS> .\Deploy-Looker.ps1 -ComputerName 20.3.144.237 -Username uipath -Password Pas$w0rd -LookerZipFilePath C:\install\Insights_Lookerfiles_20220610102005.zip

  .EXAMPLE
  PS> .\Deploy-Looker.ps1 -ComputerName 20.3.144.237 -Username uipath -Password Pas$w0rd -LookerZipFilePath C:\install\Insights_Lookerfiles_20220610102005.zip -OfflineBundleFilePath "C:\install\looker_image.tar.zip"
#>


# Parameters
param(
    [Parameter(Mandatory=$true)][string]$ComputerName,
    [int]$Port = 22,
    [Parameter(Mandatory=$true)][string]$Username,
    [string]$Password = "",
    [string]$KeyfilePath = "",
    [string]$SudoPass = "",
    [string]$DeployDir = "~",
    [Parameter(Mandatory=$true)][string]$LookerZipFilePath,
    [string]$LookerImageFilePath = "",
    [string]$LookerImageVersionTag = "",
    [string]$OfflineBundleFilePath = "",
    [bool]$BypassSystemCheck = $False,
    [bool]$AutoUpdateFingerprint = $True
)

Function Test-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal( $identity )
    return $principal.IsInRole( [System.Security.Principal.WindowsBuiltInRole]::Administrator )
}

Function Write-HR() {
    $HR = "-" * $Host.UI.RawUI.WindowSize.Width
    Write-Output $HR
}

Function Get-FileName($FilePath) {
    return Split-Path $FilePath -leaf
}

Function Get-MaskedPass($Pass) {
    if ( $Pass.length -gt 0) {
        return $Pass.SubString(0, 4) + "*" * 10
    }
    return $Pass
}

Function Send-File($FilePath, $DeployDir) {
    if (-Not(Test-Path $FilePath -PathType Leaf)) {
        Write-Host -ForegroundColor Red "File $FilePath does not exists."
        exit 1
    }
    $FileName = Get-FileName($FilePath)
    Write-Output "Uploading $FileName to host $ComputerName`:$DeployDir..."
    if ($keyfilePath.Length -eq 0) {
        Set-SCPItem -ComputerName $ComputerName -AcceptKey -Credential $Credentials -Port $Port -Path $FilePath -Destination $DeployDir
    }
    else {
        Set-SCPItem -ComputerName $ComputerName -AcceptKey -Credential $Credentials -KeyFile $keyfilePath -Port $Port -Path $FilePath -Destination $DeployDir
    }
    if (-Not $?) {
        Write-Host -ForegroundColor Red "Failed to upload $FileName to host $ComputerName. Exiting..."
        exit 1
    }
}

Function Invoke-RemoteCommand($command) {
    $Result = Invoke-SSHCommand -SessionId $Session.sessionid -Command $Command -ShowStandardOutputStream -Timeout 3600
    if ($Result.ExitStatus -ne 0) {
        Write-Host -ForegroundColor Red "Failed to execute command '$Command' on host $ComputerName. Exiting..."
        Write-Host -ForegroundColor Red $Result.Error
        exit 1
    }
}

if (-not(Test-Admin)) {
    Write-Output "User is not running with administrative rights.`nPlease open a PowerShell console as administrator and try again."
    Exit 2
}

$HelpInfo = "Please use the following command to get help. `n`n    Get-Help .\Deploy-Looker.ps1`n"

if (($KeyfilePath.Length -eq 0) -and ($Password.Length -eq 0)) {
    Write-Output "At least one of the -KeyfilePath parameter or -Password parameter is required."
    Write-Output $HelpInfo
    Exit 2
}

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null

$CurrentTimestamp = $(get-date -f yyyyMMddhhmmss)

$ScriptVersion = "1.0"
$sLogName = "Deploy-Looker_$CurrentTimestamp.log"
$sLogFile = Join-Path -Path $PSScriptRoot -ChildPath $sLogName

Start-Transcript -path $sLogFile

Write-Output "`nRunning UiPath Insights Looker Server Deployment Script v$ScriptVersion"
Write-HR

$MaskedPassword = Get-MaskedPass($Password)
$MaskedSudoPass = Get-MaskedPass($SudoPass)

Write-Host "Parameters:
ComputerName = $ComputerName
Port = $Port
Username = $Username
Password = $MaskedPassword
SudoPass = $MaskedSudoPass
DeployDir = $DeployDir
KeyfilePath = $KeyfilePath
LookerZipFilePath = $LookerZipFilePath
LookerImageFilePath = $LookerImageFilePath
LookerImageVersionTag = $LookerImageVersionTag
OfflineBundleFilePath = $OfflineBundleFilePath `n"

# Check if our module loaded properly
if (-Not (Get-Module -ListAvailable -Name Posh-SSH)) {
    # install the module automatically
    Install-Module -Name Posh-SSH -Repository PSGallery -Force
}

# Includes
Import-Module Posh-SSH

# Automatically update the fingerprint for the given host.
if ($AutoUpdateFingerprint) {
    Remove-SSHTrustedHost $ComputerName | Out-Null
}

if (-Not (Test-Path $LookerZipFilePath -PathType Leaf)) {
    Write-Host -ForegroundColor Red "Cannot find Looker Zip file."
    exit 1
}

# Create Windows Host Deploy Dir
$DeployPath = "$Env:ProgramData\UiPath Insights"
New-Item -ItemType Directory -Force -Path $DeployPath | Out-Null
Write-Host "Deploy output path: $DeployPath"

if ($Password.length -gt 0) {
    $secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
}
else {
    $secpasswd = new-object System.Security.SecureString
}
$Credentials = New-Object System.Management.Automation.PSCredential($Username, $secpasswd)
if (-Not $?) {
    Write-Host -ForegroundColor Red "Cannot generate credentials. Exiting..."
    exit 1
}

Write-Host -ForegroundColor Green "`nSetting up secure connection to $ComputerName..."
if ($keyfilePath.Length -eq 0) {
    $Session = New-SSHSession -ComputerName $ComputerName -AcceptKey -Credential $Credentials  -Port $Port
}
else {
    $Session = New-SSHSession -ComputerName $ComputerName -AcceptKey -Credential $Credentials -KeyFile $keyfilePath -Port $Port
}
if (-Not $?) {
    Write-Host -ForegroundColor Red "Failed to connect to host $ComputerName. Exiting..."
    exit 1
}

if ($DeployDir -ne "~") {
    Write-Host -ForegroundColor Green "`nPreparing deploy directory..."
    Write-Output "Deploy directory: $DeployDir..."
    Write-Output "Note:"
    Write-Output " - The ownership of $DeployDir will be transferred to $Username. This is required to allow file uploads and script executions."
    Write-Output " - If this is not your first deployment, ensure that the same deploy directory as in previous deployments is being used."
    $Command = "echo `"$SudoPass`" | sudo -S mkdir -p $DeployDir;"
    $Command = $Command + "echo `"$SudoPass`" | sudo -S chown -R $Username $DeployDir"
    Invoke-RemoteCommand($Command)
}

Write-Host -ForegroundColor Green "`nUploading Looker Initialization files to $ComputerName..."
Send-File -FilePath $LookerZipFilePath -DeployDir $DeployDir

if ($LookerImageFilePath.length -gt 0) {
    Send-File -FilePath $LookerImageFilePath -DeployDir $DeployDir
}

if ($OfflineBundleFilePath.length -gt 0) {
    Send-File -FilePath $OfflineBundleFilePath -DeployDir $DeployDir
}

$LookerfileZipFileName = Get-FileName($LookerZipFilePath)
$Command = "command -v unzip &> /dev/null || { echo 'unzip not found. Installing...'; echo `"$SudoPass`" | sudo -S sudo yum install -y unzip; };"
$Command = $Command + "cd $DeployDir;"
$Command = $Command + "echo `"$SudoPass`" | sudo -S unzip -o $LookerfileZipFileName"
Write-Host -ForegroundColor Green "`nExtracting files from Insights_Lookerfiles Zip file..."
Invoke-RemoteCommand($Command)

Write-Host -ForegroundColor Green "`nRunning looker-initialization script..."
$Command = ""
if ($LookerImageVersionTag.Length -gt 0) {
    $Command = $Command + "export CONTAINER_REGISTRY='insightsdevacr.azurecr.io'; export LOOKER_VERSION_TAG='$LookerImageVersionTag'; "
}
$Command = $Command + "bash $DeployDir/insights/looker-initialization.sh -y"
if ($SudoPass.length -gt 0) {
    $Command = $Command + " -s $SudoPass"
}
if ($LookerImageFilePath.length -gt 0) {
    $LookerImageFileName = Get-FileName($LookerImageFilePath)
    $Command = $Command + " -i $DeployDir/$LookerImageFileName"
}
if ($OfflineBundleFilePath.length -gt 0) {
    $OfflineBundleFileName = Get-FileName($OfflineBundleFilePath)
    $Command = $Command + " -o $DeployDir/$OfflineBundleFileName"
}
if ($BypassSystemCheck) {
    $Command = $Command + " -b"
}
Invoke-RemoteCommand($Command)

# Remove the session
Remove-SSHSession -Name $Session | Out-Null

Write-Host -ForegroundColor Green "`nDownloading looker.json file..."
if (Test-Path $DeployPath\looker.json -PathType Leaf ) {
    Write-Output "$DeployPath\looker.json exists. Rename it to $DeployPath\looker_backup_$CurrentTimestamp.json"
    Rename-Item -Path $DeployPath\looker.json -NewName $DeployPath\looker_backup_$CurrentTimestamp.json
}

$RemoteLookerJsonFilePath = "$DeployDir/insights/looker.json"
if ($keyfilePath.Length -eq 0) {
    Get-SCPItem -ComputerName $ComputerName -AcceptKey -Credential $Credentials -Path $RemoteLookerJsonFilePath -PathType File -Destination $DeployPath
}
else {
    Get-SCPItem -ComputerName $ComputerName -AcceptKey -Credential $Credentials -KeyFile $keyfilePath -Port $Port -Path $RemoteLookerJsonFilePath -PathType File -Destination $DeployPath
}
if (-Not $?) {
    Write-Host -ForegroundColor Red "Failed to download looker.json. You can manually download it using the following command`n scp $Username@${ComputerName}:'${RemoteLookerJsonFilePath}' '$DeployPath'"
    exit 1
}
Write-Output "Saved the file to $DeployPath\looker.json"

Write-Host -ForegroundColor Green "`nUiPath Insights Looker Server deployed successfully!"

Write-Host -ForegroundColor Green "`nPreview of the looker.json file"
Write-HR
Get-Content "$DeployPath\looker.json"
Start-Process $DeployPath
Write-HR

Stop-Transcript
