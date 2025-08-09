function Get-ExpiredPasswords {
    [CmdletBinding()]
    param(
        [TimeSpan]$MaxAge    = (New-TimeSpan -Days 90),
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
                        @{N='Reason';E={ if ($_.PasswordLastSet) { "PasswordAge>${MaxAgeDays}d" } else { 'PasswordUnset' } }},
                      @{N='Severity';E={'Medium'}}
}
