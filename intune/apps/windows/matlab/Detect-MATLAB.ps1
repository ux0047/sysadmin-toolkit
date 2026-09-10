<#
.SYNOPSIS
  Detects MATLAB installation using executable and install log
.NOTES
  Version:        1.0
  Author:         BINOD SYANGTAN
  Creation Date:  TUESDAY, 03 FEBRUARY 2026
#>

# Paths
$exePath     = "C:\MATLAB\R2025b\bin\matlab.exe"
$mInstallLog = "C:\TEMP\matlab_install.log"

# Timing
$timeoutSec = 1800   # 30 minutes
$pollSec    = 10

Write-Host "Starting MATLAB detection..."

# Step 1: Check executable first
if (-not (Test-Path -Path $exePath -PathType Leaf)) {
    Write-Host "MATLAB executable not found at: $exePath"
    Write-Host "Application not installed."
    exit 1
}

Write-Host "MATLAB executable found at: $exePath"

# Step 2: Wait for install log completion
$endStatus = $null
$startTime = Get-Date

Write-Host "Waiting for install log ($mInstallLog) to contain completion marker..."

do {
    if (Test-Path -Path $mInstallLog -PathType Leaf) {

        $hit = Select-String -Path $mInstallLog `
            -Pattern 'End - Successful','End - Unsuccessful' `
            -SimpleMatch `
            -ErrorAction SilentlyContinue | Select-Object -Last 1

        if ($hit) {
            $endStatus = $hit.Line
            Write-Host "Detected log line: $endStatus"
        }
        else {
            Write-Host "No completion marker yet in log."
        }

    }
    else {
        Write-Host "Install log not present yet..."
    }

    if (-not $endStatus) { Start-Sleep -Seconds $pollSec }

} while (-not $endStatus -and ((Get-Date) - $startTime).TotalSeconds -lt $timeoutSec)

# Step 3: Final decision
if ($endStatus -match 'End - Successful') {
    Write-Host "MATLAB installation detected successfully."
    exit 0
}
else {
    if (-not $endStatus) {
        Write-Host "Timed out waiting for install log completion."
    }
    elseif ($endStatus -match 'End - Unsuccessful') {
        Write-Host "MATLAB installation failed according to log."
    }
    else {
        Write-Host "Install status undetermined. Investigate. Last detected log line: $endStatus"
    }
    exit 1
}
