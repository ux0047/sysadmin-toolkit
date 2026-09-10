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

 # 🔐 Generate password
        $Password = New-StrongPassword -Length 16
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
