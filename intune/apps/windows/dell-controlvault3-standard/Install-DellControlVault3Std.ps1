#Requires -RunAsAdministrator
# Install-ControlVault-Std.ps1
# Runs extracted Dell ControlVault (Standard/G7K77) payload directly, only on allowed models.

<#
.SYNOPSIS
    Installs Dell ControlVault (Standard/G7K77) silently, restricted to an approved model list.

.DESCRIPTION
    The script:
    - Checks the local device model against an allowlist of Dell Latitude/Precision/Pro Max models
    - Verifies the extracted payload (CVHCI64.exe) exists next to the script
    - Executes the InstallShield wrapper silently with MSI logging enabled
    - Returns success (0) when:
        • Install completes (0), or
        • Install requests reboot (3010)
      Returns 0 (no-op) if the model is not in scope, so Intune won’t retry.
    - Writes a verbose MSI log to C:\TEMP\ControlVaultInstall.log

.NOTES
    Author  : Binod Syangtan
    Version : 1.0.0
    Date    : 15 August 2025

.REQUIREMENTS
    - Windows 10/11
    - Local Administrator privileges (script enforces with #Requires)
    - Extracted ControlVault Standard (G7K77) payload placed alongside this script:
        • CVHCI64.exe plus its related files (e.g., mup.xml, package.xml, production\)
    - Execution Policy permitting this script

.INPUTS
    None. (All configuration is in-script.)

.OUTPUTS
    - MSI log file at: C:\TEMP\ControlVaultInstall.log
    - Exit codes:
        • 0     : Success or not-applicable model (no-op)
        • 3010  : Considered success (reboot required)
        • Other : Installer’s native exit code

.EXAMPLE
    .\Install-ControlVault-Std.ps1
    Runs a silent install on supported models; otherwise exits 0 without changes.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# ----- Standard (G7K77) model list -----
$AllowedModels = @(
  "Dell Pro Max Slim FCS1250","Dell Pro Max Slim XE FCS1250",
  "Dell Pro Max Tower T2 FCT2250","Dell Pro Max Tower T2 XE FCT2250",
  "Latitude 5300","Latitude 5300 2-in-1","Latitude 5310","Latitude 5310 2-in-1",
  "Latitude 5320","Latitude 5330","Latitude 5340","Latitude 5400",
  "Latitude 5401","Latitude 5410","Latitude 5411","Latitude 5420",
  "Latitude 5421","Latitude 5430","Latitude 5430 Rugged","Latitude 5431",
  "Latitude 5440","Latitude 5500","Latitude 5501","Latitude 5510",
  "Latitude 5511","Latitude 5520","Latitude 5521","Latitude 5530",
  "Latitude 5531","Latitude 5540","Latitude 7030 Rugged Extreme Tablet",
  "Latitude 7200 2-in-1","Latitude 7210 2-in-1","Latitude 7220 Rugged Extreme Tablet",
  "Latitude 7220EX Rugged Extreme Tablet","Latitude 7230 Rugged Extreme Tablet",
  "Latitude 7300","Latitude 7310","Latitude 7320","Latitude 7320 Detachable",
  "Latitude 7330","Latitude 7330 Rugged Extreme","Latitude 7340","Latitude 7400",
  "Latitude 7400 2-in-1","Latitude 7410","Latitude 7420","Latitude 7430",
  "Latitude 7440","Latitude 7520","Latitude 7530","Latitude 7640",
  "Latitude 9330","Latitude 9410","Latitude 9420","Latitude 9430",
  "Latitude 9440 2-in-1","Latitude 9510","Latitude 9520",
  "Precision 3450 Small Form Factor","Precision 3450 XE Small Form Factor",
  "Precision 3460 Small Form Factor","Precision 3460 XE Small FormFactor",
  "Precision 3470","Precision 3480","Precision 3540","Precision 3541",
  "Precision 3550","Precision 3551","Precision 3560","Precision 3561",
  "Precision 3570","Precision 3571","Precision 3580","Precision 3581",
  "Precision 3650 Tower","Precision 3650 XE Tower","Precision 3660 Tower",
  "Precision 3660 XE Tower","Precision 3680 Tower","Precision 3680 XE Tower",
  "Precision 5470","Precision 5480","Precision 5680","Precision 7540",
  "Precision 7550","Precision 7560","Precision 7670","Precision 7680",
  "Precision 7740","Precision 7750","Precision 7760","Precision 7770","Precision 7780"
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
    Write-Host "Model '$Model' not in Standard list. Skipping."
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
