<#
.SYNOPSIS
    This script retrieves mailbox permission details (FullAccess, SendAs, and SendOnBehalf) for shared mailboxes listed in a CSV file.

.DESCRIPTION
    The script:
    - Imports shared mailbox identities from a CSV file
    - Queries each mailbox for:
        - FullAccess permissions (non-inherited)
        - SendAs permissions
        - SendOnBehalf permissions
    - Exports each type of permission to separate timestamped CSV files

.NOTES
    Author: Binod Syangtan
    Date: 10 April 2025
    Version: 1.0.1

.REQUIREMENTS
    - Exchange Online PowerShell module (e.g., ExchangeOnlineManagement)
    - Appropriate permissions to run mailbox permission queries
    - Mailbox identities must exist and be accessible to the connected session
    - CSV input file should have a column named 'Identity'

.INPUTS
    CSV file containing shared mailbox UPNs or aliases under a column named 'Identity'

.OUTPUTS
    Three separate CSV files containing:
        - FullAccess mailbox permissions
        - SendAs permissions
        - SendOnBehalf permissions

.EXAMPLE
    Run the script in PowerShell:
    .\Export-SharedMailboxMemberPermissions.ps1
#>

# ========================
# Author  : Binod Syangtan
# Version : 1.0.1
# Date    : 07 March 2025
# ========================

# === File Paths ===
$inputPath = "C:\Temp\input\sharedmailboxes.csv"
$outputPath = "C:\Temp\output"

# Ensure output directory exists
if (-not (Test-Path $outputPath)) {
    Write-Output "Output Path does not exist. Creating path: $outputPath"
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
} else {
    Write-Output "Output Path exists: $outputPath"
}

# Timestamp for filenames
$timestamp = Get-Date -Format "ddMMyyyy-HHmm"

# Output file names
$outputFileName_FullPerms    = "FullAccessSharedMailboxUsersPermissions-$timestamp.csv"
$outputFileName_SendAsPerms  = "SendAsSharedMailboxUsersPermissions-$timestamp.csv"
$outputFileName_SendOnBehalf = "SendOnBehalfSharedMailboxUsersPermissions-$timestamp.csv"

# Full paths
$outputPathFile_FullPerms    = Join-Path -Path $outputPath -ChildPath $outputFileName_FullPerms
$outputPathFile_SendAsPerms  = Join-Path -Path $outputPath -ChildPath $outputFileName_SendAsPerms
$outputPathFile_SendOnBehalf = Join-Path -Path $outputPath -ChildPath $outputFileName_SendOnBehalf

# === Import Shared Mailbox List ===
$sharedmailboxes = Import-Csv $inputPath

# === Loop Through Each Mailbox ===
foreach ($sharedmailbox in $sharedmailboxes) {
    $mailboxidentityName = $sharedmailbox.Identity

    if (-not [string]::IsNullOrWhiteSpace($mailboxidentityName)) {
        Write-Output "Processing mailbox: $mailboxidentityName"

        try {
            # --- FullAccess Permissions ---
            $fullPerms = Get-MailboxPermission -Identity $mailboxidentityName |
                         Where-Object {
                             $_.AccessRights -eq "FullAccess" -and
                             $_.IsInherited -eq $false -and
                             $_.User -notlike "NT AUTHORITY\SELF"
                         }

            $formattedFullPerms = $fullPerms | Select-Object -Property 
                @{Name='Username'; Expression = {$_.User}},
                @{Name='Access';   Expression = {$_.AccessRights}},
                @{Name='Mailbox';  Expression = {$mailboxidentityName}}

            $formattedFullPerms | Export-Csv -Path $outputPathFile_FullPerms -Append -NoTypeInformation -Force

            # --- SendAs Permissions ---
            $sendAsPerms = Get-RecipientPermission -Identity $mailboxidentityName |
                           Where-Object { $_.Trustee -notlike "NT AUTHORITY\SELF" }

            $formattedSendAsPerms = $sendAsPerms | Select-Object -Property 
                @{Name='Username'; Expression = {$_.Trustee}},
                @{Name='Access';   Expression = {$_.AccessRights}},
                @{Name='Mailbox';  Expression = {$mailboxidentityName}}

            $formattedSendAsPerms | Export-Csv -Path $outputPathFile_SendAsPerms -Append -NoTypeInformation -Force

            # --- SendOnBehalf Permissions ---
            $mailbox = Get-Mailbox -Identity $mailboxidentityName -ErrorAction Stop

            foreach ($delegate in $mailbox.GrantSendOnBehalfTo) {
                $record = [PSCustomObject]@{
                    Mailbox  = $mailboxidentityName
                    Delegate = $delegate.Name
                    Access   = "SendOnBehalf"
                }

                $record | Export-Csv -Path $outputPathFile_SendOnBehalf -Append -NoTypeInformation -Force
            }

        } catch {
            Write-Warning "Error processing $mailboxidentityName: $_"
        }
    }
}
