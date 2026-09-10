#Requires -RunAsAdministrator
# Install-ControlVault-Plus.ps1
# Runs extracted Dell ControlVault (PLUS/TWF65) payload directly, only on allowed models.

<#
.SYNOPSIS
    This script installs Dell ControlVault (PLUS/TWF65) silently on approved models only.

.DESCRIPTION
    The script:
    - Checks the local device model against an allowlist of Dell Pro, Latitude, and Precision models
    - Verifies that the extracted ControlVault PLUS (TWF65) payload (CVHCI64.exe) is present next to this script
    - Executes the InstallShield wrapper silently with MSI logging enabled
    - Returns success (0) if installation completes or requests reboot (3010)
    - Returns 0 with no changes if the model is not on the PLUS list to prevent Intune retries
    - Writes a detailed MSI log to C:\TEMP\ControlVaultInstall.log

.NOTES
    Author  : Binod Syangtan
    Date    : 15 August 2025
    Version : 1.0.0

.REQUIREMENTS
    - Windows 10/11
    - Local Administrator privileges
    - Extracted ControlVault PLUS (TWF65) payload in the same directory as this script:
        • CVHCI64.exe plus mup.xml, package.xml, and production\ directory
    - Execution Policy allowing script execution

.INPUTS
    None. All configuration values are defined in the script.

.OUTPUTS
    Exit Codes:
        0     : Success or not-applicable model (no-op)
        3010  : Success, reboot required
        Other : Installer’s native exit code
    Log File:
        C:\TEMP\ControlVaultInstall.log

.EXAMPLE
    .\Install-ControlVault-Plus.ps1
    Runs the silent install on supported models; otherwise exits with 0 without changes.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# ----- PLUS (TWF65) model list -----
$AllowedModels = @(
  "Dell Pro 13 Plus PB13250","Dell Pro 13 Plus PB13255",
  "Dell Pro 14 Plus PB14250","Dell Pro 14 Plus PB14255",
  "Dell Pro 16 Plus PB16250","Dell Pro 16 Plus PB16255",
  "Dell Pro Max 14 MC14250","Dell Pro Max 16 MC16250",
  "Dell Pro Max 16 Plus MB16250","Dell Pro Max 16 XE MC16250",
  "Dell Pro Max 18 Plus MB18250","Dell Pro Rugged 13 RA13250",
  "Dell Pro Rugged 14 RB14250","Latitude 5350","Latitude 5450",
  "Latitude 5550","Latitude 7350","Latitude 7450","Latitude 7650",
  "Latitude 9450 2-in-1","Mobile Precision 3591","Mobile Precision 5690",
  "Precision 3490","Precision 3590","Precision 5490"
)

# ----- Paths -----
$Payload = Join-Path $PSScriptRoot 'CVHCI64.exe'  # extracted payload next to this PS1
$MsiLog  = 'C:\TEMP\ControlVaultInstall.log'

# Ensure log directory, but don't pre-write MSI log
$logDir = Split-Path $MsiLog
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
if (Test-Path $MsiLog) { Remove-Item $MsiLog -Force -ErrorAction SilentlyContinue }

# ----- Model check -----
$Model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model.Trim()
if ($AllowedModels -notcontains $Model) {
    Write-Host "Model '$Model' not in PLUS list. Skipping."
    exit 0  # no-op success so Intune doesn't retry
}

# Sanity check payload presence
if (-not (Test-Path $Payload)) {
    Write-Error "Payload not found: $Payload"
    exit 2
}

# ----- Silent install (InstallShield-style payload): /s then /v"MSI args" -----
# Keep WorkingDirectory = $PSScriptRoot so CVHCI64.exe can find mup.xml, package.xml, production\
$Args = @(
    '/s',
    "/v`"/qn REBOOT=ReallySuppress MUP_SUPPORT=1 /l*v `"$MsiLog`"`""
)

$proc = Start-Process -FilePath $Payload `
                      -ArgumentList $Args `
                      -WorkingDirectory $PSScriptRoot `
                      -WindowStyle Hidden `
                      -PassThru -Wait

switch ($proc.ExitCode) {
    0     { exit 0 }  # success
    3010  { exit 0 }  # success, reboot required (let Intune policy handle)
    default {
        Write-Host "Installer returned exit code $($proc.ExitCode). See $MsiLog"
        exit $proc.ExitCode
    }
}
