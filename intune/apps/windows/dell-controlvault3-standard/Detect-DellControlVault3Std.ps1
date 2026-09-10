#Requires -RunAsAdministrator
# DetectDellControlVault3.ps1
# Detects successful installation or firmware upgrade of Dell ControlVault3 (Standard/G7K77).

<#
.SYNOPSIS
    This script checks for the successful installation or firmware upgrade of Dell ControlVault3 (Standard/G7K77).

.DESCRIPTION
    The script:
    - Checks the ControlVault firmware upgrade log for:
        • A successful firmware upgrade message
        • The expected Standard ControlVault firmware version (5.15.7.0)
    - If the firmware log does not confirm installation, it checks the ControlVault installer log for:
        • Successful installation entries
        • Successful reconfiguration entries
    - Returns success if either method detects a valid install/upgrade.

.NOTES
    Author  : Binod Syangtan
    Date    : 15 August 2025
    Version : 1.0.0

.REQUIREMENTS
    - Windows 10/11
    - Local Administrator privileges
    - Access to:
        • C:\Windows\System32\CVFirmwareUpgradeLog.txt
        • C:\TEMP\ControlVaultInstall.log

.INPUTS
    None. All paths and patterns are defined in-script.

.OUTPUTS
    Exit Code:
        0 : Detection success
        1 : Detection failed

.EXAMPLE
    .\DetectDellControlVault3.ps1
    Runs detection checks and returns 0 if Dell ControlVault3 is successfully installed or upgraded.
#>

$ErrorActionPreference = 'SilentlyContinue'

# ----- Paths -----
$controlvault_VerUpgradelog = "C:\Windows\System32\CVFirmwareUpgradeLog.txt"
$controlvault_InstallLog    = "C:\TEMP\ControlVaultInstall.log"

# ----- 1) Firmware upgrade log check -----
if (Test-Path $controlvault_VerUpgradelog) {
    $fwLog     = Get-Content -Path $controlvault_VerUpgradelog
    $fwSuccess = $fwLog | Select-String -Pattern 'Control Vault firmware upgrade successful'
    $stdVer    = $fwLog | Select-String -Pattern '5.15.7.0'

    if ($fwSuccess -and $stdVer) {
        Write-Host "Detection success via firmware log."
        exit 0
    }
}

# ----- 2) Installer log check -----
if (Test-Path $controlvault_InstallLog) {
    $instLog = Get-Content -Path $controlvault_InstallLog

    # Install success
    $msiOK  = $instLog | Select-String -Pattern 'Windows Installer installed the product'
    $exitOK = $instLog | Select-String -Pattern 'Installation success or error status: 0'

    # Reconfiguration success
    $msiReconfig  = $instLog | Select-String -Pattern 'Windows Installer reconfigured the product'
    $exitReconfig = $instLog | Select-String -Pattern 'Reconfiguration success or error status: 0'

    if ( ($msiOK -and $exitOK) -or ($msiReconfig -and $exitReconfig) ) {
        Write-Host "Detection success via installer log."
        exit 0
    }
}

Write-Host "Detection failed - no matching log entries."
exit 1
