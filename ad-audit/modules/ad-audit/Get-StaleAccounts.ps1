function Get-StaleAccounts {
    [CmdletBinding()]
    param(
        [TimeSpan]$InactiveFor = (New-TimeSpan -Days 90),
        [string]  $SearchBase  = (Get-ADDomain).DistinguishedName
    )

    $cutoff = (Get-Date) - $InactiveFor

    Get-ADUser -Filter * -SearchBase $SearchBase -Properties Enabled,lastLogonDate |
        Where-Object {
              $_.Enabled -eq $true -and (                       
                  $_.lastLogonDate -eq $null   -or              
                  $_.lastLogonDate -lt $cutoff                 
              )
        } |
        Select-Object SamAccountName,
                      @{N='Reason';E={ if ($_.PasswordLastSet) { "PasswordAge>${MaxAgeDays}d" } else { 'PasswordUnset' } }},
                      @{N='LastLogonDate';E={ $_.lastLogonDate }},
                      @{N='Severity';     E={ 'High' }}
}
