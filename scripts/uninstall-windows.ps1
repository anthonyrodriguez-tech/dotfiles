# uninstall-windows.ps1 -- undo install.ps1.
#
#   .\scripts\uninstall-windows.ps1            # remove scoop apps + chezmoi state
#   .\scripts\uninstall-windows.ps1 -Full      # also nuke scoop itself
#   .\scripts\uninstall-windows.ps1 -Force     # skip confirmation

#Requires -Version 5.1
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Coloured uninstall output')]
[CmdletBinding()]
param([switch]$Full, [switch]$Force)

$ErrorActionPreference = 'Continue'

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "  v $Msg"  -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  ! $Msg"  -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "  x $Msg"  -ForegroundColor Red }
function Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err 'Do not run this script as Administrator.'
    exit 1
}

if (-not $Force) {
    $scope = if ($Full) { 'Scoop apps + chezmoi state + scoop itself' } else { 'Scoop apps + chezmoi state (scoop preserved)' }
    Write-Warn "This will remove: $scope"
    $reply = Read-Host 'Continue? (y/N)'
    if ($reply -notmatch '^[yY]') { Write-Ok 'aborted'; exit 0 }
}

Write-Step 'stop background processes'
$scoopRoot = Join-Path $env:USERPROFILE 'scoop'
$stuck = Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith($scoopRoot, [StringComparison]::OrdinalIgnoreCase) }
$stuck | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process claude, wezterm-gui, nvim -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Step 'chezmoi purge'
if (Test-Cmd chezmoi) {
    chezmoi purge --force 2>&1 | Out-Host
}
foreach ($d in @('.local\share\chezmoi', '.config\chezmoi', '.cache\chezmoi')) {
    $p = Join-Path $env:USERPROFILE $d
    if (Test-Path $p) { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $p }
}

Write-Step 'Claude + omp'
foreach ($n in @('claude.exe', 'omp.exe', 'omp.cmd', 'omp')) {
    $p = Join-Path $env:USERPROFILE ".local\bin\$n"
    if (Test-Path $p) { Remove-Item -Force -ErrorAction SilentlyContinue $p }
}
foreach ($d in @('.claude', '.claude.json', '.omp')) {
    $p = Join-Path $env:USERPROFILE $d
    if (Test-Path $p) { Write-Warn "kept $p -- delete manually if desired" }
}

Write-Step 'Scoop apps'
$scoopApps = @(
    'JetBrainsMono-NF', 'wezterm',
    'yq', 'jq', 'gh', 'zoxide', 'eza', 'bat', 'fd', 'ripgrep', 'fzf',
    'starship', 'delta', 'lazygit', 'neovim', 'chezmoi', 'git'
)
if (Test-Cmd scoop) {
    foreach ($p in $scoopApps) { scoop uninstall $p 2>&1 | Out-Null }
    Write-Ok 'scoop apps removed'
}

if ($Full) {
    Write-Step 'remove scoop'
    if (Test-Cmd scoop) { scoop uninstall scoop 2>&1 | Out-Host }
    if (Test-Path $scoopRoot) {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $scoopRoot
    }
    [Environment]::SetEnvironmentVariable('SCOOP', $null, 'User')
}

Write-Step 'done'
Write-Ok 'open a new terminal so PATH refreshes'
if (-not $Full) { Write-Warn 'scoop preserved -- re-run with -Full to remove it as well' }
