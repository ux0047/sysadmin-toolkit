<#
.SYNOPSIS
    This script connects to Microsoft Graph and checks if a list of devices exist in Entra ID based on their device name.

.DESCRIPTION
    The script:
    - Connects to Microsoft Graph with delegated permissions under the staff tenant
    - Imports a list of device names from a CSV file
    - Queries each device by its display name in Entra ID
    - Outputs results to the console and exports them to a CSV file

.NOTES
    Author: Binod Syangtan
    Date: 08 July 2025
    Version: 1.0.0

.REQUIREMENTS
    - PowerShell 7.0 or higher (recommended)
    - Microsoft.Graph PowerShell Module
    - Required Scope: Device.Read.All
    - CSV input file should have a column named 'DeviceName'

.INPUTS
    CSV file with device names

.OUTPUTS
    Console table of results
    CSV file indicating whether each device exists in Entra ID

.EXAMPLE
    Run the script in PowerShell:
    .\Check-EntraIDDeviceExistence.ps1
#>

# ========================
# Author  : Binod Syangtan
# Version : 1.0.0
# Date    : 08 July 2025
# ========================


# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Device.Read.All"

# Timestamp for output file
$timestamp = Get-Date -Format "ddMMyyyy-HHmm"

# Define file paths
$inputPath = "C:\TEMP\devicecheckentra.csv"  # CSV should contain 'DeviceName' column
$outputPath = "C:\Temp\output"
$outputFileName = "DeviceExistenceReport-$timestamp.csv"
$outputPathFileName = Join-Path -Path $outputPath -ChildPath $outputFileName

# Import device list from CSV
$deviceList = Import-Csv -Path $inputPath

# Initialize results array
$results = @()

# Ensure output directory exists
if (-not (Test-Path $outputPath)) {
    Write-Output "Output Path does not exist. Creating path: $outputPath"
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
} else {
    Write-Output "Output Path exists: $outputPath"
}

# Loop through each device and check if it exists
foreach ($device in $deviceList) {
    $deviceName = $device.DeviceName

    try {
        $deviceInfo = Get-MgDevice -Filter "displayName eq '$deviceName'" -Property DisplayName -ErrorAction Stop

        if ($deviceInfo) {
            $results += [PSCustomObject]@{
                DeviceName = $deviceName
                Exists     = "Exists in Entra ID"
            }
        } else {
            $results += [PSCustomObject]@{
                DeviceName = $deviceName
                Exists     = "Not Found"
            }
        }
    } catch {
        $results += [PSCustomObject]@{
            DeviceName = $deviceName
            Exists     = "Not Found"
        }
    }
}

# Output results to console
$results | Format-Table -AutoSize

# Export results to CSV
$results | Export-Csv -Path $outputPathFileName -NoTypeInformation

# Completion message
Write-Output "Device existence report exported to path: $outputPathFileName"
