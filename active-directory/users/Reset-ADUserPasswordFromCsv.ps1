Import-Module ActiveDirectory

function New-StrongPassword {
    param (
        [int]$Length = 16
    )

    if ($Length -lt 14) {
        throw "Password length must be at least 14 characters."
    }

    $Upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $Lower   = 'abcdefghijklmnopqrstuvwxyz'
    $Numbers = '0123456789'
    $Symbols = '!@#$%^&*()_-+=[]{}'
    $All     = ($Upper + $Lower + $Numbers + $Symbols).ToCharArray()

    $Rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    function Get-SecureChar {
        param ([char[]]$CharSet)

        $bytes = New-Object byte[] 4
        do {
            $Rng.GetBytes($bytes)
            $value = [BitConverter]::ToUInt32($bytes, 0)
            $max = [uint32]::MaxValue - ([uint32]::MaxValue % $CharSet.Length)
        } while ($value -ge $max)

        return $CharSet[$value % $CharSet.Length]
    }

    $PasswordChars = @(
        Get-SecureChar $Upper.ToCharArray()
        Get-SecureChar $Lower.ToCharArray()
        Get-SecureChar $Numbers.ToCharArray()
        Get-SecureChar $Symbols.ToCharArray()
    )

    while ($PasswordChars.Count -lt $Length) {
        $PasswordChars += Get-SecureChar $All
    }

    $PasswordChars = $PasswordChars | Sort-Object {
        $bytes = New-Object byte[] 4
        $Rng.GetBytes($bytes)
        [BitConverter]::ToUInt32($bytes, 0)
    }

    -join $PasswordChars
}

$InputCsv  = "C:\temp\input\UserAccounts.csv"
$OutputCsv = "C:\Temp\output\PasswordResetResults.csv"

$Users = Import-Csv $InputCsv
$Results = @()

foreach ($User in $Users) {
    $SamAccountName = $User.SamAccountName

    try {
        # 🔍 Check if user exists
        $ADUser = Get-ADUser -Identity $SamAccountName -ErrorAction Stop

        # 🔐 Generate password
        $Password = New-StrongPassword -Length 16
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

        # 🔄 Reset password
        Set-ADAccountPassword `
            -Identity $SamAccountName `
            -NewPassword $SecurePassword `
            -Reset

        # 🚫 Do NOT force change at logon
        Set-ADUser `
            -Identity $SamAccountName `
            -ChangePasswordAtLogon $false

        $Results += [PSCustomObject]@{
            SamAccountName = $SamAccountName
            Password       = $Password
            Status         = "Success"
            Error          = ""
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        $Results += [PSCustomObject]@{
            SamAccountName = $SamAccountName
            Password       = ""
            Status         = "NotFound"
            Error          = "User does not exist"
        }
    }
    catch {
        $Results += [PSCustomObject]@{
            SamAccountName = $SamAccountName
            Password       = ""
            Status         = "Failed"
            Error          = $_.Exception.Message
        }
    }
}

$Results | Export-Csv $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Password reset completed. Results exported to $OutputCsv"
