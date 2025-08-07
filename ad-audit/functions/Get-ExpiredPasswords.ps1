function Get-ExpiredPasswords {
    [CmdletBinding()]
    param(
        # ile dni hasło może żyć – domyślnie 90
        [TimeSpan]$MaxAge    = (New-TimeSpan -Days 90),
        # skąd szukamy – domyślnie cały las
        [string]  $SearchBase = (Get-ADDomain).DistinguishedName
    )

    $cutoff = (Get-Date) - $MaxAge

    Get-ADUser -Filter * -SearchBase $SearchBase `
               -Properties PasswordLastSet,PasswordNeverExpires,Enabled |
        Where-Object {
            $_.Enabled -eq $true -and                             
            $_.PasswordNeverExpires -eq $false -and               
            ($_.PasswordLastSet -eq $null -or                     
             $_.PasswordLastSet -lt $cutoff)                      
        } |
        Select-Object SamAccountName, PasswordLastSet,
                      @{N='Severity';E={'Medium'}}
}
