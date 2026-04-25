# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Windows-native maintenance pass — same scope as the POSIX
#         dotfiles-update, but uses scoop directly without going through
#         MSYS2. Run from PowerShell (powershell.exe or pwsh).
# WHERE : home/dot_local/bin/dotfiles-update.ps1
#         → ~/.local/bin/dotfiles-update.ps1  (deployed by chezmoi)
# WHY   : MSYS2 zsh can already call dotfiles-update (POSIX), but a
#         PowerShell variant is handy when the user lives in pwsh and
#         wants a one-liner: `dotfiles-update.ps1`.
#
# Usage:
#   dotfiles-update.ps1                # full pass
#   dotfiles-update.ps1 -Quick         # only chezmoi + nvim Lazy sync
#   dotfiles-update.ps1 -NoPkg         # skip scoop upgrade
# ─────────────────────────────────────────────────────────────────────────

#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Quick,
    [switch]$NoPkg
)

$ErrorActionPreference = 'Continue'

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "  v $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  ! $Msg" -ForegroundColor Yellow }
function Write-Skip { param([string]$Msg, [string]$Reason) Write-Host "  - $Msg (skipped — $Reason)" -ForegroundColor Yellow }
function Test-Cmd   { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# ── 1. Scoop ──────────────────────────────────────────────────────────────
if ($Quick -or $NoPkg) {
    Write-Skip 'scoop update' '-Quick or -NoPkg'
}
elseif (Test-Cmd scoop) {
    Write-Step 'scoop update *'
    scoop update
    scoop update '*'
}
else {
    Write-Warn 'scoop not on PATH — skipping system upgrade'
}

# ── 2. chezmoi update ─────────────────────────────────────────────────────
if (Test-Cmd chezmoi) {
    Write-Step 'chezmoi update'
    chezmoi update --apply
}
else {
    Write-Warn 'chezmoi not on PATH — skipping'
}

# ── 3. mise upgrade ───────────────────────────────────────────────────────
if ($Quick) {
    Write-Skip 'mise upgrade' '-Quick'
}
elseif (Test-Cmd mise) {
    Write-Step 'mise upgrade'
    mise upgrade
}
else {
    Write-Skip 'mise upgrade' 'mise not installed'
}

# ── 4. LazyVim plugins ────────────────────────────────────────────────────
if (Test-Cmd nvim) {
    Write-Step 'nvim — Lazy! sync'
    nvim --headless '+Lazy! sync' +qa
}
else {
    Write-Skip 'nvim Lazy sync' 'nvim not installed'
}

# ── 5. Mason update ───────────────────────────────────────────────────────
if ($Quick) {
    Write-Skip 'Mason update' '-Quick'
}
elseif (Test-Cmd nvim) {
    Write-Step 'nvim — MasonUpdate'
    nvim --headless +MasonUpdate +qa
}

# ── 6. AI CLIs (best-effort) ──────────────────────────────────────────────
if ($Quick) {
    Write-Skip 'AI CLI updates' '-Quick'
}
else {
    if ((Test-Cmd bun) -and (Test-Cmd omp)) {
        Write-Step 'omp — bun update -g'
        bun update -g '@oh-my-pi/pi-coding-agent'
    }
    elseif (Test-Cmd omp) {
        Write-Skip 'omp update' 'bun not installed (re-run upstream installer to upgrade)'
    }

    if (Test-Cmd claude) {
        Write-Step 'claude — self-update'
        try { claude update } catch { Write-Skip 'claude update' 'command not supported by this version' }
    }
}

Write-Step 'done'
Write-Ok 'open a fresh terminal to pick up any dotfile changes'
