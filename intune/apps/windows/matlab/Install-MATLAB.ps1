
<#
.SYNOPSIS
  Installs MATLAB R2025b (offline) using setup.exe + installer_input.txt (Intune Win32) and can be followed for any version R20XXy.
.DESCRIPTION
  Uses Intune-staged content ($PSScriptRoot). Runs installer silently via input file and waits for completion.
.INPUT
  installer_input.txt is the installer/config file for MATLAB
.OUTPUT
  Log file stored in C:\TEMP\matlab_install.log
.NOTES
  Version:        1.0
  Author:         BINOD SYANGTAN
  Creation Date:  TUESDAY, 03 FEBRUARY 2026
#>

$sourcePath  = $PSScriptRoot
$mInstallLog = "C:\TEMP\matlab_install.log"
$tempFolder  = "C:\TEMP"
$setupExe    = Join-Path $sourcePath "setup.exe"
$inputFile   = Join-Path $sourcePath "installer_input.txt"

$ErrorActionPreference = "Stop"

try {
    Write-Host "Starting MATLAB install..."
    Write-Host "Source path: $sourcePath"

    # Ensure C:\TEMP exists
    if (-not (Test-Path -Path $tempFolder -PathType Container)) {
        New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
        Write-Host "Created: $tempFolder"
    }

    # Validate required files
    if (-not (Test-Path -Path $setupExe -PathType Leaf)) {
        Write-Host "ERROR: setup.exe not found at: $setupExe"
        exit 1
    }

    if (-not (Test-Path -Path $inputFile -PathType Leaf)) {
        Write-Host "ERROR: installer_input.txt not found at: $inputFile"
        exit 1
    }

    # Remove old log to avoid stale detection
    if (Test-Path -Path $mInstallLog -PathType Leaf) {
        Remove-Item -Path $mInstallLog -Force -ErrorAction SilentlyContinue
        Write-Host "Removed old log: $mInstallLog"
    }

    Write-Host "Running MATLAB installer..."
    $proc = Start-Process -FilePath $setupExe `
        -ArgumentList "-inputFile `"$inputFile`"" `
        -Wait -PassThru

    Write-Host "Installer exit code: $($proc.ExitCode)"

    if ($proc.ExitCode -eq 0) {
        Write-Host "MATLAB install completed successfully."
        exit 0
    }
    else {
        Write-Host "MATLAB install failed."
        exit 1
    }
}
catch {
    Write-Host "Install script failed: $($_.Exception.Message)"
    exit 1
}
