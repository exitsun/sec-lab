function Get-PrivilegedAccounts {
    [CmdletBinding()]
    param(
        [string[]]$Groups    = @('Domain Admins','Enterprise Admins','Schema Admins','Administrators'),
        [string[]]$SkipList  = @('Administrator','krbtgt')
    )

    $users = @()

    foreach ($g in $Groups) {
        try {
            $members = Get-ADGroupMember -Identity $g -Recursive -ErrorAction Stop |
                       Where-Object { $_.objectClass -eq 'user' } |
                       ForEach-Object {
                           Get-ADUser -Identity $_.SamAccountName -Properties Enabled,SamAccountName
                       }

            $users += $members |
                      Where-Object { $_.Enabled -and $_.SamAccountName -notin $SkipList } |
                      Select-Object SamAccountName,
                                    @{N='SourceGroup';E={$g}},
                                    @{N='Reason';E={"Privileged:$g"}},
                                    @{N='Severity';E={
                                        if ($g -in @('Domain Admins','Enterprise Admins','Schema Admins')) {'Critical'}
                                        elseif ($g -in @('Administrators','DnsAdmins','Server Operators')) {'High'}
                                        else {'Medium'}
                                    }}
        }
        catch {
            Write-Warning "Nie pobrałem członków grupy '$g': $($_.Exception.Message)"
        }
    }

    $users | Sort-Object SamAccountName -Unique
}
