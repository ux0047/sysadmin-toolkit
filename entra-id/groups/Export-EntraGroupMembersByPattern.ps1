<#
.SYNOPSIS
Searches Microsoft Entra ID (Azure AD) groups by name pattern and exports user members of matched groups to CSV files.

.DESCRIPTION
This script connects to Microsoft Graph and searches for Entra ID groups whose DisplayName matches one or more 
text patterns defined in the $groupSearchText variable.

Microsoft Graph group search is token-based. The script first uses server-side -Search to narrow down candidate groups, 
then applies a client-side wildcard match (-like "*pattern*") to ensure reliable matching of group names that contain 
the specified text anywhere in the DisplayName.

For example, if $groupSearchText contains "ProjectX", the script will match groups such as:
- ProjectX
- ProjectX-H1-2026
- Finance-ProjectX
- AU-ProjectX-Students
- Test-ProjectX-Group

.NOTES
    Author: BINOD SYANGTAN
    Date: FRIDAY 20 FEBRUARY 2026
    Version: 1.0.0

For each matched group, the script retrieves all user members and exports them to individual CSV files.

.INPUTS
Group name patterns are defined directly inside the script.

.OUTPUTS
CSV files — One file per matched group.

Each CSV contains:
- DisplayName
- UserPrincipalName
- Id

Files are named using the format:
<GroupDisplayName>-members-<timestamp>.csv

.REQUIREMENTS
- Microsoft Graph PowerShell SDK installed
- Internet connectivity
- Microsoft Graph permissions:
    - Group.Read.All
    - User.Read.All
- Successful authentication via Connect-MgGraph

.LIMITATIONS
- Microsoft Graph -Search is token-based and does not support true wildcard syntax.
- Final pattern matching is enforced using PowerShell wildcard filtering.
- Nested group members are not expanded.
- Only user objects (microsoft.graph.user) are exported.
- Group names containing invalid Windows filename characters may cause export errors.

.LINK
Microsoft Graph PowerShell SDK:
https://learn.microsoft.com/powershell/microsoftgraph/overview

.EXAMPLE
    Run the script in PowerShell:
    .\Export-EntraGroupMembersByNamePattern.ps1
#>

# ========================
# Author  : BINOD SYANGTAN
# Version : 1.0.0
# Date    : FRIDAY 20 FEBRUARY 2026
# ========================


# Connect to Graph
Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All"

# 🔹 Define the group name PATTERNS here
$groupSearchText = @(
    "groupname1",
    "groupname2"
)


# Timestamp for file naming
$timestamp = Get-Date -Format "ddMMyyyy-HHmm"

# Output folder
$outputDir = "C:\Temp\GroupMembersExtract"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null


Write-Host "Searching for groups starting with: $($groupSearchText -join ', ')"


# Server-side filter using contains()
$targetGroups = foreach ($gp in $groupSearchText) {
    Get-MgGroup -All `
                -Search "`"displayName:$gp`"" `
                -ConsistencyLevel eventual `
                -CountVariable groupCount
}


$targetGroupsS = $targetGroups | Where-Object {
    $name = $_.DisplayName
    $groupSearchText | Where-Object { $name -like "$_*" } | Select-Object -First 1
}


if ($targetGroupsS.Count -eq 0) {
    Write-Host "No groups found containing '$groupSearchText' in the name."
    return
}

Write-Host "$groupCount group(s) found."

foreach ($group in $targetGroupsS) {

    $csvFileName = "$($group.DisplayName)-members-$timestamp.csv"
    $csvPath = Join-Path $outputDir $csvFileName

    Write-Host "Fetching members for group: $($group.DisplayName)"

    $members = Get-MgGroupMember -GroupId $group.Id -All

    $memberList = foreach ($member in $members) {

        if ($member.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user') {

            $user = Get-MgUser -UserId $member.Id -Property DisplayName,UserPrincipalName,Id

            [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Id                = $user.Id
            }
        }
    }

    if ($memberList) {
        $memberList | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Exported members to $csvPath"
    }
    else {
        Write-Host "No user members found in $($group.DisplayName). No file created."
    }
}

Write-Host "Script completed."
