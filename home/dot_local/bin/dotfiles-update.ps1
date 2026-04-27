# dotfiles-update.ps1 -- Windows maintenance pass.
#
#   dotfiles-update.ps1            # full pass
#   dotfiles-update.ps1 -NoPkg     # skip scoop upgrade

#Requires -Version 5.1
[CmdletBinding()]
param([switch]$NoPkg)

$ErrorActionPreference = 'Continue'

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "  v $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  ! $Msg" -ForegroundColor Yellow }
function Test-Cmd   { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

if (-not $NoPkg -and (Test-Cmd scoop)) {
    Write-Step 'scoop update *'
    scoop update
    scoop update '*'
}

if (Test-Cmd chezmoi) {
    Write-Step 'chezmoi update'
    chezmoi update --apply
}

if (Test-Cmd nvim) {
    Write-Step 'nvim -- Lazy! sync'
    nvim --headless '+Lazy! sync' +qa
}

if (Test-Cmd claude) {
    Write-Step 'claude -- self-update'
    try { claude update } catch { Write-Warn 'claude update unsupported' }
}
if ((Test-Cmd bun) -and (Test-Cmd omp)) {
    Write-Step 'omp -- bun update'
    bun update -g '@oh-my-pi/pi-coding-agent'
}

Write-Step 'done'
Write-Ok 'open a fresh terminal to pick up dotfile changes'
