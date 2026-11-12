<#
  .SYNOPSIS
  Installs all required software for Insights.

  .DESCRIPTION
  Enables IIS and installs the pinned .NET Hosting Bundle.

  .EXAMPLE
  PS> .\Install-Prerequisites.ps1
#>

$ScriptVersion = "1.0"
$HostingBundleVersion = "10.0.9"
$HostingBundleSha512 = "597B7BA22DB3ECFB2897F0443A6986741833E1DABF13128013FFA92342DD1509A46661C04E38782FD47D0AAFD6D2373CC9AB54242140C388500C46909EA2DD67"

function Test-InsightsAdministrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
    $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-InsightsTranscriptStart {
    param([Parameter(Mandatory)][string] $Path)

    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    Start-Transcript -Path $Path -ErrorAction Stop | Out-Null
}

function Invoke-InsightsTranscriptStop {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}

function Enable-InsightsWebServerRole {
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart -ErrorAction Stop | Out-Null
}

function Test-InsightsFile {
    param([Parameter(Mandatory)][string] $Path)

    Test-Path -Path $Path -PathType Leaf
}

function Save-InsightsDownload {
    param(
        [Parameter(Mandatory)][string] $Url,
        [Parameter(Mandatory)][string] $Path
    )

    $webClient = [System.Net.WebClient]::new()
    try {
        $webClient.DownloadFile($Url, $Path)
    }
    finally {
        $webClient.Dispose()
    }
}

function Get-InsightsFileSha512 {
    param([Parameter(Mandatory)][string] $Path)

    (Get-FileHash -Path $Path -Algorithm SHA512 -ErrorAction Stop).Hash
}

function Invoke-InsightsFileRemoval {
    param([Parameter(Mandatory)][string] $Path)

    Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
}

function Invoke-InsightsHostingBundleInstaller {
    param([Parameter(Mandatory)][string] $Path)

    $process = Start-Process $Path -ArgumentList "/install /quiet /norestart" -Wait -NoNewWindow -PassThru -ErrorAction Stop
    try {
        $process.ExitCode
    }
    finally {
        $process.Dispose()
    }
}

function Invoke-InsightsIisRestart {
    & iisreset /restart | Out-Null
    $LASTEXITCODE
}

function Invoke-InsightsPrerequisiteInstall {
    if (-not (Test-InsightsAdministrator)) {
        Write-Information "User is not running with administrative rights.`nPlease open a PowerShell console as administrator and try again." -InformationAction Continue
        return 2
    }

    $logFile = Join-Path -Path $PSScriptRoot -ChildPath "Install-InsightsPrerequisites.log"
    $hostingBundleFileName = "dotnet-hosting-$HostingBundleVersion-win.exe"
    $hostingBundleUrl = "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/$HostingBundleVersion/$hostingBundleFileName"
    $hostingBundleInstallerPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath $hostingBundleFileName
    $transcriptStarted = $false
    $previousErrorActionPreference = $ErrorActionPreference

    try {
        $ErrorActionPreference = "Stop"
        Invoke-InsightsTranscriptStart -Path $logFile
        $transcriptStarted = $true

        Write-Information "" -InformationAction Continue
        Write-Information "Running UiPath Insights Prerequisites Installation Script v$ScriptVersion" -InformationAction Continue
        Write-Information "" -InformationAction Continue
        Write-Information "***************************************************************************************************" -InformationAction Continue
        Write-Information "" -InformationAction Continue
        Write-Information "Enabling IIS-WebServerRole..." -InformationAction Continue
        Enable-InsightsWebServerRole

        if (-not (Test-InsightsFile -Path $hostingBundleInstallerPath)) {
            Write-Information "" -InformationAction Continue
            Write-Information "Downloading Dotnet Hosting Bundle $HostingBundleVersion..." -InformationAction Continue
            try {
                Save-InsightsDownload -Url $hostingBundleUrl -Path $hostingBundleInstallerPath
            }
            catch {
                Invoke-InsightsFileRemoval -Path $hostingBundleInstallerPath
                throw
            }
        }

        Write-Information "Verifying Dotnet Hosting Bundle integrity (SHA512)..." -InformationAction Continue
        $actualSha512 = Get-InsightsFileSha512 -Path $hostingBundleInstallerPath
        if ($actualSha512 -ne $HostingBundleSha512) {
            Invoke-InsightsFileRemoval -Path $hostingBundleInstallerPath
            throw "Hosting Bundle SHA512 mismatch. Expected $HostingBundleSha512 but got $actualSha512. The download may be corrupt or tampered with; aborting."
        }

        Write-Information "Installing Dotnet Hosting Bundle..." -InformationAction Continue
        $exitCode = Invoke-InsightsHostingBundleInstaller -Path $hostingBundleInstallerPath
        if ($null -eq $exitCode) {
            throw "Dotnet Hosting Bundle installer did not return an exit code."
        }
        if ($exitCode -ne 0 -and $exitCode -ne 3010) {
            throw "Dotnet Hosting Bundle installer exited with code $exitCode."
        }
        if ($exitCode -eq 3010) {
            Write-Information "Dotnet Hosting Bundle installed; a reboot is required to complete installation." -InformationAction Continue
        }

        Write-Information "" -InformationAction Continue
        Write-Information "Restarting IIS..." -InformationAction Continue
        $iisExitCode = Invoke-InsightsIisRestart
        if ($iisExitCode -ne 0) {
            throw "Failed to restart IIS. iisreset exit code: $iisExitCode."
        }

        return 0
    }
    catch {
        Write-Information "ERROR: $($_.Exception.Message)" -InformationAction Continue
        return 1
    }
    finally {
        if ($transcriptStarted) {
            Invoke-InsightsTranscriptStop
        }
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-InsightsPrerequisiteInstall)
}
