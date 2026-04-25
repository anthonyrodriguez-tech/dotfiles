# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Windows-native health check — verifies all expected binaries are
#         on PATH, runs nvim + chezmoi diagnostics.
# WHERE : home/dot_local/bin/dotfiles-doctor.ps1
#         → ~/.local/bin/dotfiles-doctor.ps1  (deployed by chezmoi)
# WHY   : Mirror of the POSIX dotfiles-doctor for users who live in pwsh.
#
# Usage:
#   dotfiles-doctor.ps1            # full report
#   dotfiles-doctor.ps1 -Quiet     # only show problems (good for CI)
# ─────────────────────────────────────────────────────────────────────────

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
              'starship', 'atuin', 'mise', 'lazygit', 'delta', 'jq', 'scoop')
$optional = @('gh', 'yq', 'claude', 'omp', 'bun', 'wezterm-gui')

foreach ($b in $required) {
    $cmd = Get-Command $b -ErrorAction SilentlyContinue
    if ($cmd) { Write-Ok "$b ($($cmd.Source))" }
    else      { Write-Miss "$b — required"; $missCount++ }
}

foreach ($b in $optional) {
    $cmd = Get-Command $b -ErrorAction SilentlyContinue
    if ($cmd) { Write-Ok "$b ($($cmd.Source))" }
    else      { Write-Warn "$b — optional"; $warnCount++ }
}

Write-Step 'MSYS2 layer'
$msys2Bash = Join-Path $env:USERPROFILE 'scoop\apps\msys2\current\usr\bin\bash.exe'
if (Test-Path $msys2Bash) { Write-Ok "MSYS2 bash present at $msys2Bash" }
else { Write-Miss "MSYS2 bash missing — bootstrap-windows.ps1 not completed?"; $missCount++ }

Write-Step 'local overrides'
foreach ($f in @(
    (Join-Path $env:USERPROFILE '.gitconfig.local'),
    (Join-Path $env:USERPROFILE '.gitconfig.work')
)) {
    if (Test-Path $f) { Write-Ok "$f present" }
    elseif (-not $Quiet) { Write-Host "       $f (not present)" }
}

if (Test-Cmd chezmoi) {
    Write-Step 'chezmoi doctor'
    chezmoi doctor
}

if (Test-Cmd nvim) {
    Write-Step 'nvim startup smoke'
    $errFile = Join-Path $env:TEMP 'dotfiles-doctor-nvim.err'
    nvim --headless +qa 2> $errFile
    if (Test-Path $errFile) {
        $stderr = Get-Content $errFile -Raw
        if ($stderr) {
            Write-Warn 'nvim wrote to stderr on startup:'
            $stderr -split "`n" | ForEach-Object { Write-Host "         $_" }
            $warnCount++
        }
        else { Write-Ok 'nvim starts cleanly' }
        Remove-Item $errFile -ErrorAction SilentlyContinue
    }
}

Write-Step 'summary'
if (($missCount -eq 0) -and ($warnCount -eq 0)) {
    Write-Host '  v all clear' -ForegroundColor Green
    exit 0
}
Write-Host "  $missCount missing, $warnCount warnings"
if ($missCount -gt 0) { exit 1 } else { exit 0 }
