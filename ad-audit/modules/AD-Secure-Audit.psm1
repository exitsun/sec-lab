$results = @()
$results += Get-StaleAccounts
$results += Get-ExpiredPasswords
$results += Get-PrivilegedAccounts
$results += Get-PasswordNeverExpires


$results = $results | Select-Object SamAccountName, Reason, LastLogonDate, Severity, PasswordNeverExpires

# change the path to your template file
$template = Get-Content "C:\Users\Administrator\templates\report-template.html" -Raw
$rows = $results | ForEach-Object {
    "<tr class='table-$($_.Severity.ToLower())'>
       <td>$($_.SamAccountName)</td>
       <td>$($_.LastLogonDate)</td>
       <td>$($_.Severity)</td>
       <td>$($_.Reason)</td>
       <td>$($_.PasswordNeverExpires)</td>
     </tr>"
}
($template -replace '{{ROWS}}', ($rows -join "`n")) |
  Out-File "C:\Users\Administrator\Desktop\AD security report $(Get-Date -f yyyy-MM-dd).html" -Encoding UTF8
