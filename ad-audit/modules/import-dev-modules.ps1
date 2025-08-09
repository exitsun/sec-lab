
$funcDir = "$HOME\Desktop\functions"
$files   = Get-ChildItem $funcDir -Filter *.ps1 -ErrorAction Stop
if (-not $files) { throw "Brak plików *.ps1 w: $funcDir" }

# build module
$code = ($files | Get-Content -Raw) -join "`n"
$sb   = [ScriptBlock]::Create($code)
$mod  = New-Module -Name AdAudit -ScriptBlock $sb
Import-Module $mod -Force

# confirmation
Get-Command -Module AdAudit
