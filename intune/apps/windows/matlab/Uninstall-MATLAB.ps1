<#
.SYNOPSIS
  Uninstalls MATLAB silently using MathWorks uninstaller
.NOTES
  Version:        1.0
  Author:         BINOD SYANGTAN
  Creation Date:  TUESDAY, 03 FEBRUARY 2026
  This works for version R2024a and Newer
#>

$uninstaller = "C:\MATLAB\R2025b\bin\win64\MathWorksProductUninstaller.exe"

Write-Host "Starting MATLAB uninstall..."

if (-not (Test-Path -Path $uninstaller -PathType Leaf)) {
    Write-Host "MathWorks uninstaller not found at: $uninstaller"
    Write-Host "MATLAB may already be uninstalled."
    exit 0
}
else {
Write-Host "Uninstaller found. Running silent uninstall..."
}

$proc = Start-Process -FilePath $uninstaller `
    -ArgumentList "--mode silent" `
    -Wait -PassThru

Write-Host "Uninstaller exited with code: $($proc.ExitCode)"

if ($proc.ExitCode -eq 0) {
    Write-Host "MATLAB R2024b uninstalled successfully."
    exit 0
}
else {
    Write-Host "MATLAB R2024b uninstall may have failed. Investigate. "
    exit $proc.ExitCode
}
