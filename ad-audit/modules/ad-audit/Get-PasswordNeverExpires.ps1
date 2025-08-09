function Get-PasswordNeverExpires {
    [CmdletBinding()]
    param(
        [string]$SearchBase = (Get-ADDomain).DistinguishedName
    )

    Get-ADUser -Filter * -SearchBase $SearchBase -Properties Enabled,PasswordNeverExpires,MemberOf |
    Where-Object { $_.Enabled -and $_.PasswordNeverExpires } |
    Select-Object
        SamAccountName,
        @{ Name = 'Reason';   Expression = { 'PasswordNeverExpires' } },
        @{ Name = 'Severity'; Expression = {
            if ($_.MemberOf -match 'CN=Domain Admins,') { 'Critical' } else { 'High' }
        }}
}
