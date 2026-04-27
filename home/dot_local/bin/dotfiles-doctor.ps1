# dotfiles-doctor.ps1 -- Windows health check.

#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Quiet)

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) if (-not $Quiet) { Write-Host "  OK   $Msg" -ForegroundColor Green } }
function Write-Miss { param([string]$Msg) Write-Host "  MISS $Msg" -ForegroundColor Red }
function Write-Warn { param([string]$Msg) Write-Host "  WARN $Msg" -ForegroundColor Yellow }
function Test-Cmd   { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

$missCount = 0
$warnCount = 0

Write-Step 'binaries on PATH'
$required = @('git', 'nvim', 'chezmoi', 'fzf', 'zoxide', 'rg', 'fd', 'bat', 'eza',
              'starship', 'lazygit', 'delta', 'jq', 'scoop')
$optional = @('gh', 'yq', 'claude', 'omp', 'bun', 'wezterm-gui')

foreach ($b in $required) {
    $cmd = Get-Command $b -ErrorAction SilentlyContinue
    if ($cmd) { Write-Ok "$b ($($cmd.Source))" }
    else      { Write-Miss "$b -- required"; $missCount++ }
}
foreach ($b in $optional) {
    $cmd = Get-Command $b -ErrorAction SilentlyContinue
    if ($cmd) { Write-Ok "$b ($($cmd.Source))" }
    else      { Write-Warn "$b -- optional"; $warnCount++ }
}

Write-Step 'local overrides'
foreach ($f in @(
    (Join-Path $env:USERPROFILE '.gitconfig.local'),
    (Join-Path $env:USERPROFILE '.gitconfig.work')
)) {
    if (Test-Path $f) { Write-Ok "$f present" }
}

if (Test-Cmd chezmoi) {
    Write-Step 'chezmoi doctor'
    chezmoi doctor
}

if (Test-Cmd nvim) {
    Write-Step 'nvim startup smoke'
    $errFile = Join-Path $env:TEMP 'dotfiles-doctor-nvim.err'
    nvim --headless +qa 2> $errFile
    if ((Test-Path $errFile) -and (Get-Item $errFile).Length -gt 0) {
        Write-Warn 'nvim wrote to stderr on startup:'
        Get-Content $errFile | ForEach-Object { Write-Host "         $_" }
        $warnCount++
    }
    else { Write-Ok 'nvim starts cleanly' }
    Remove-Item $errFile -ErrorAction SilentlyContinue
}

Write-Step 'summary'
if (($missCount -eq 0) -and ($warnCount -eq 0)) {
    Write-Host '  v all clear' -ForegroundColor Green
    exit 0
}
Write-Host "  $missCount missing, $warnCount warnings"
if ($missCount -gt 0) { exit 1 } else { exit 0 }
