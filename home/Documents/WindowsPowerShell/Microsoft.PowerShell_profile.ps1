# Stub for Windows PowerShell 5.1 — dot-sources the canonical profile
# under Documents\PowerShell so we maintain a single file.
$canonical = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
if (Test-Path $canonical) { . $canonical }
