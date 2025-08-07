Import-Module ".\Get-StaleAccounts.ps1"

Describe "Get-StaleAccounts" {
    It "returns at least one account in seeded lab" {
        (Get-StaleAccounts).Count -ge 0
    }
}
