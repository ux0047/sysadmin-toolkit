<#
.SYNOPSIS
    This script connects to Microsoft Graph and checks the status (enabled/disabled) of a list of users in Entra ID based on their UserPrincipalName (UPN).

.DESCRIPTION
    The script:
    - Connects to Microsoft Graph with delegated permissions
    - Imports a list of users from a CSV file
    - Queries each user's status from Entra ID
    - Outputs results to the console and a CSV file

.NOTES
    Author: Binod Syangtan
    Date: 07 March 2025
    Version: 1.0

.REQUIREMENTS
    - PowerShell 7.0 or higher (recommended)
    - Microsoft.Graph PowerShell Module
    - Required Scope: User.Read.All
    - CSV input file should have a column named 'UserPrincipalName'

.INPUTS
    CSV file with user UPNs

.OUTPUTS
    Console table of results
    CSV file with status of users

 
.EXAMPLE
    Run the script in PowerShell:
    .\Check-EntraIDUserStatus.ps1
#>

# ========================
# Author  : Binod Syangtan
# Version : 1.0.0
# Date    : 07 March 2025
# ========================

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All"

#timestamp for outputfile
$timestamp = Get-Date -Format "ddMMyyyy-HHmm"

# Define file paths
$inputPath = "C:\Temp\input\upncheckentraid.csv"
$outputPath = "C:\Temp\output"

#Filename of the output file in csv format
$outputFileName = "UserStatusReport-$timestamp.csv"

# Full path of the output file to export the results
$outputPathFileName = Join-Path -Path $outputPath -ChildPath $outputFileName

# Import user list from CSV (ensure CSV has 'UserPrincipalName' column)
$usersList = Import-Csv -Path $inputPath


# Initialize results array
$results = @()

# Ensure output directory exists
if (-not (Test-Path $outputPath)){
    Write-Output "Output Path does not exists. Creating path: $outputPath"
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
  }else{ Write-Output "Output Path exists: $outputPath"}

# Loop through each user and check status
foreach ($user in $usersList) {
    $upn = $user.UserPrincipalName

    try {
        $userInfo = Get-MgUser -UserId $upn -Property Id, DisplayName, UserPrincipalName, AccountEnabled -ErrorAction Stop |
                    Select-Object Id, DisplayName, UserPrincipalName, AccountEnabled

        $status = if ($userInfo.AccountEnabled) { "Enabled" } else { "Disabled" }

        $results += [PSCustomObject]@{
            UserPrincipalName = $userInfo.UserPrincipalName
            DisplayName       = $userInfo.DisplayName
            Status            = $status
        }
    }
    catch {
        $results += [PSCustomObject]@{
            UserPrincipalName = $upn
            DisplayName       = "Not Found"
            Status            = "Not Found in Entra ID"
        }
    }
}

# Output results to console
$results | Format-Table -AutoSize

# Export results to CSV
$results | Export-Csv -Path $outputPathFileName -NoTypeInformation

# Completion message
Write-Output "User status report exported to path: $outputPathFileName"
