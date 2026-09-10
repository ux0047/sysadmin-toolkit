<#
.SYNOPSIS
  This script is used to REMOVE FullAccess and SendAs users permissions in particular mailbox and provide the Read Only Permission to required users.
.DESCRIPTION
  This script is used to REMOVE FullAccess and SendAs users permissions in particular mailbox and provide the Read Only Permission to required users.
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  SharedMailboxes - $allSharedMailboxes, 
  UserEmail - $userListRO
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         BINOD SYANGTAN
  Creation Date:  TUESDAY, 19 NOVEMBER 2024
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>




#----------------------------------------------------------[Declarations/Initialisations]------------------------------------------------

#Created Array List; List of Sharedmailboxes for which user lists are provided Read-only Access
$allSharedMailboxes = @(

    "mail_1@abc.com"
    

)

#Created Array List; List of users to be provided with Read only Access
$userListRO = @(

    "user_1@abc.com"
    "user_2@abc.com"

)

#-----------------------------------------------------------[Main Execution]------------------------------------------------------------

foreach($sharedmailboxes in $allSharedMailboxes){

    #Extracting the mailbox permisions
    $userExistedPermsList = Get-MailboxPermission -Identity $SharedMailboxes | Where-Object { $_.User -notlike "NT AUTHORITY\SELF" }

    #Extracting the list of existed users who have access to the mailbox
    $userExistedList = $userExistedPermsList.user

    #Extracting the trustee permissions(SendAs) for mailbox
    $userSendAsPermsExisted = Get-RecipientPermission -Identity $sharedmailboxes | Where-Object { $_.Trustee -notlike "NT AUTHORITY\SELF" -and ($_.Trustee -notlike "NT AUTHORITY\SYSTEM")}

    #Extracting the trustee lists for mailbox
    $userSendAsList = $userSendAsPermsExisted.Trustee
    

    foreach($userTrustee in $userSendAsList){

        Remove-RecipientPermission -Identity $sharedmailboxes -Trustee $userTrustee -AccessRights SendAs
        Write-Output "$sharedmailboxes; SendAs Permissions removed for user: $userTrustee"
    }

    foreach($user in $userExistedList){
        #Removing exiting mailbox permissions for each user
        Remove-MailboxPermission -Identity $sharedmailboxes -User $user -AccessRights FullAccess -InheritanceType All -Confirm:$False
        Write-Host "$sharedmailboxes; User Removed is: $user"
    }

    foreach($userList in $userListRO){
        #Adding Read-only mailbox permissions for each user
        Add-MailboxPermission -Identity $sharedmailboxes -User $userList -AccessRights ReadPermission -InheritanceType All -Confirm:$False
        Write-Output "$sharedmailboxes; Read only accss provided to $userList"
    }    

}

#-----------------------------------------------------------[Validation]------------------------------------------------------------

#Validation of Mailbox Access
foreach($sharedmailboxes in $allSharedMailboxes){

    #Extracting the mailbox permisions
    $userExistedPermsList = Get-MailboxPermission -Identity $SharedMailboxes | Where-Object { $_.User -notlike "NT AUTHORITY\SELF" }
    
    #Displaying the current mailbox access
    $userExistedPermsList | Format-List
}



#validation of SendAs perms
foreach($sharedmailboxes in $allSharedMailboxes){

    #Extracting the trustee permissions
    $userSendAsPermsExisted = Get-RecipientPermission -Identity $sharedmailboxes | Where-Object { $_.Trustee -notlike "NT AUTHORITY\SELF" }

    #Displaying the current SendAs list
    $userSendAsPermsExisted | Format-List
    
}


