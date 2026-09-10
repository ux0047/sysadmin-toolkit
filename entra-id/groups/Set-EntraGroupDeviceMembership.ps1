<#
.SYNOPSIS
    This script connects to Microsoft Graph and adds or removes devices from an Entra ID group based on the device name.

.DESCRIPTION
    The script:
    - Connects to Microsoft Graph using delegated permissions
    - Prompts the user to add or remove devices
    - Uses hardcoded arrays for device and group names
    - Checks if each device exists in Entra ID
    - Checks group membership and adds/removes devices accordingly
    - Logs all actions to a timestamped log file

.NOTES
    Author: Binod Syangtan
    Date: 03 July 2025
    Version: 1.0.0

.REQUIREMENTS
    - PowerShell 7.0 or higher
    - Microsoft.Graph PowerShell Module
    - Required Scopes: Group.ReadWrite.All, Device.Read.All, Directory.Read.All

.INPUTS
    Device display name(s) (defined in array or input source)
    Entra Group Name
    $deviceNames = @("Device01", "Device02", "Device03")    # Replace with actual device display names that you want to add or remove from the group
    $groupNames = @("Group01", "Group02", "Group03")        # Replace with actual group display names

.OUTPUTS
    Log file with detailed execution output

.EXAMPLE
    .\Add-Remove-Device-ToFrom-Group.ps1

    This will prompt the user to choose between adding or removing a device from a specific group, then process accordingly.
#>

# ========================
# Author  : Binod Syangtan
# Version : 1.0.0
# Date    : 03 July 2025
# ========================

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "Group.ReadWrite.All", "Device.Read.All", "Directory.Read.All"
    $mgContext = Get-MgContext
    $me = Get-MgUser -UserId $mgContext.Account -ErrorAction Stop
    Write-Host "✅ Connected to Microsoft Graph as: $($me.DisplayName) <$($me.UserPrincipalName)>"
} catch {
    Write-Host "❌ Failed to connect to Microsoft Graph. Details: $_"
    return
}

# Define log file path
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = "C:\Logs\Add_Remove_Device-$timestamp.log"
New-Item -Path $logPath -ItemType File -Force | Out-Null

# Define logging helper with timestamp
function Write-Log {
    param ([string]$message)
    $timeStampedMsg = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $message"
    Write-Output $timeStampedMsg
    Add-Content -Path $logPath -Value $timeStampedMsg
}

# Function to add device to group
function Add-DeviceToGroup {
    param (
        [string]$deviceName,
        [string]$deviceId,
        [string]$groupId,
        [string]$groupName
    )
    $refUrl = "https://graph.microsoft.com/v1.0/directoryObjects/$deviceId"
    New-MgGroupMemberByRef -GroupId $groupId -BodyParameter @{ "@odata.id" = $refUrl }
    Write-Log "✅ ADDED: Device '$deviceName' (ID: $deviceId) added to group '$groupName'."
}

# Function to remove device from group
function Remove-DeviceFromGroup {
    param (
        [string]$deviceName,
        [string]$deviceId,
        [string]$groupId,
        [string]$groupName
    )
    Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $deviceId
    Write-Log "✅ REMOVED: Device '$deviceName' removed from group '$groupName'."
}

# Function to process device based on action
function Process-DeviceAction {
    param (
        [string]$deviceName,
        [string]$groupId,
        [string]$groupName,
        [string]$action
    )
    try {
        Write-Log "`n🔎 Checking for device '$deviceName' in Entra ID..."
        $device = Get-MgDevice -Filter "displayName eq '$deviceName'"

        if (-not $device) {
            Write-Log "❌ Device '$deviceName' not found in Entra ID."
            return
        }

        $deviceId = $device.Id
        Write-Log "✅ Device '$deviceName' exists. ID: $deviceId"

        $isMember = Get-MgGroupMember -GroupId $groupId -All | Where-Object { $_.Id -eq $deviceId }

        switch ($action) {
            "add" {
                if ($isMember) {
                    Write-Log "ℹ️ Device '$deviceName' is already a member of group '$groupName'. No further action required."
                } else {
                    Write-Log "ℹ️ Device '$deviceName' is not a member of group '$groupName'."
                    Add-DeviceToGroup -deviceName $deviceName -deviceId $deviceId -groupId $groupId -groupName $groupName
                }
            }
            "remove" {
                if ($isMember) {
                    Write-Log "ℹ️ Device '$deviceName' is a member of group '$groupName'."
                    Remove-DeviceFromGroup -deviceName $deviceName -deviceId $deviceId -groupId $groupId -groupName $groupName
                } else {
                    Write-Log "ℹ️ Device '$deviceName' is not a member of group '$groupName'. No further action required."
                }
            }
            default {
                Write-Log "❌ Unknown action '$action'. Skipping device."
            }
        }
    }
    catch {
        Write-Log "❌ ERROR while processing device '$deviceName'. Details: $_"
    }
}

# Prompt for action using numbers
Write-Host "Select action:`n1. Add device to group`n2. Remove device from group"
$choice = Read-Host "Enter your choice (1 or 2)"

switch ($choice) {
    "1" { $action = "add" }
    "2" { $action = "remove" }
    default {
        Write-Log "❌ Invalid selection '$choice'. Please enter 1 or 2. Exiting script."
        return
    }
}

# Define devices and groups
$deviceNames = @("Device01", "Device02", "Device03")    # Replace with actual device display names that you want to add or remove from the group
$groupNames = @("Group01", "Group02", "Group03")        # Replace with actual group display names

# Resolve groups
$resolvedGroups = @{}
foreach ($name in $groupNames) {
    $group = Get-MgGroup -Filter "displayName eq '$name'"
    if ($group) {
        $resolvedGroups[$name] = $group.Id
        Write-Log "✅ Group '$name' found with ID: $($group.Id)"
    } else {
        Write-Log "❌ Group '$name' not found. Skipping."
    }
}

if ($resolvedGroups.Count -eq 0) {
    Write-Log "❌ No valid groups were found. Exiting script."
    return
}

# Loop through groups and devices
foreach ($groupName in $resolvedGroups.Keys) {
    $groupId = $resolvedGroups[$groupName]
    foreach ($deviceName in $deviceNames) {
        Process-DeviceAction -deviceName $deviceName -groupId $groupId -groupName $groupName -action $action
    }
}

Write-Log "`n✅ Script execution completed. Log saved to: $logPath"
