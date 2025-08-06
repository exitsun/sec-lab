<#
    Seeder for creating users:
      25 users  OU=Users-Active
      5  users  OU=Users-Disabled (enabled=$false)
      4 users  OU=Users-Expired  (ChangePasswordAtLogon)
      3  of the active go to Domain Admins
      Creates missing OUs first
      Idempotent - no duplications of exsisting accounts
     
#>

param(
    [string]$RootOU  = "OU=Lab,$((Get-ADDomain).DistinguishedName)",
    [int]   $Active  = 25,
    [int]   $Disabled= 5,
    [int]   $Expired = 4,
    [int]   $Admins  = 3
)

Import-Module ActiveDirectory

function Ensure-OU ($dn) {
    if (-not (Get-ADOrganizationalUnit -Identity $dn -ErrorAction SilentlyContinue)) {
        $name = ($dn -split ',',2)[0] -replace 'OU='
        $parent = ($dn -split ',',2)[1]
        New-ADOrganizationalUnit -Name $name -Path $parent -ProtectedFromAccidentalDeletion:$false
    }
}


@('Users-Active','Users-Disabled','Users-Expired').ForEach{
    Ensure-OU "OU=$_,${RootOU}"
}


$rand = 2000
function New-Login { "labuser{0}" -f (++$script:rand) }
function New-Pw    { [guid]::NewGuid().ToString('N').Substring(0,12)+'!' }

function New-LabUser {
    param($ou, [bool]$enabled=$true, [switch]$expirePw)
    $sam = New-Login
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") { return }   # idempotent
    $pw  = ConvertTo-SecureString (New-Pw) -AsPlainText -Force
    New-ADUser -Sam $sam -Name $sam -Path $ou -AccountPassword $pw -Enabled:$enabled `
               -PasswordNeverExpires:$false -ChangePasswordAtLogon:$false -ErrorAction Stop
    if ($expirePw) { Set-ADUser $sam -ChangePasswordAtLogon $true }
    return $sam
}

$ouAct = "OU=Users-Active,$RootOU"
$ouDis = "OU=Users-Disabled,$RootOU"
$ouExp = "OU=Users-Expired,$RootOU"

$created = @()
1..$Active  | % { $created += New-LabUser $ouAct  $true          }
1..$Disabled| % { New-LabUser $ouDis  $false       }
1..$Expired | % { New-LabUser $ouExp  $true -expirePw }

$created | Select-Object -First $Admins | ForEach-Object {
    Add-ADGroupMember 'Domain Admins' $_
}

Write-Host " Seed complete. Active:$Active Disabled:$Disabled Expired:$Expired Admins added:$Admins"
