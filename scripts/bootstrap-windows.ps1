# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Windows bootstrap — Scoop (user-level) + MSYS2 + chezmoi.
# WHERE : scripts/bootstrap-windows.ps1
# WHY   : Safran / any corporate Windows laptop where we don't have admin
#         and can't install WSL2. Scoop runs entirely under %USERPROFILE%;
#         MSYS2 provides the POSIX layer (zsh, coreutils) that our dotfiles
#         assume. WezTerm is the Windows terminal, launched from its own
#         shortcut rather than from cmd.exe.
#
# Usage (PowerShell, no admin):
#   irm https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-windows.ps1 | iex
#   # Or clone the repo and:
#   .\scripts\bootstrap-windows.ps1
#
# Safe to re-run; nothing is reinstalled if already present.
# ─────────────────────────────────────────────────────────────────────────

#Requires -Version 5.1
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Intentional: colorised output in a bootstrap script')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'Intentional: Scoop official installer requires iex')]
[CmdletBinding()]
param(
    [string]$RepoUrl = $(if ($env:DOTFILES_REPO) { $env:DOTFILES_REPO } else { 'https://github.com/tony/dotfiles.git' })
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "  v $Msg"  -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  ! $Msg"  -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "  x $Msg"  -ForegroundColor Red }

function Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# Fail early if we're somehow running elevated — the whole point of this
# script is to work for a non-admin user. Scoop explicitly refuses elevated
# installs and mixing admin/user Scoop state is a known footgun.
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err 'Do not run this script as Administrator. Scoop must install under your user profile.'
    exit 1
}

# Ensure ExecutionPolicy allows running the script in this session.
if ((Get-ExecutionPolicy -Scope CurrentUser) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
    Write-Step 'Setting CurrentUser ExecutionPolicy to RemoteSigned (no admin needed)'
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
}

# ── 1. Scoop ──────────────────────────────────────────────────────────────
Write-Step 'Scoop'
if (Test-Cmd scoop) {
    Write-Ok 'already installed'
}
else {
    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
}

# Refresh PATH so the newly-installed scoop is callable below.
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'User') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'Machine')

# ── 2. Scoop buckets ──────────────────────────────────────────────────────
# `scoop bucket add` errors if the bucket already exists — swallow that.
Write-Step 'Scoop buckets'
foreach ($b in @('main', 'extras', 'nerd-fonts')) {
    scoop bucket add $b 2>$null
    Write-Ok "bucket ${b}"
}

# ── 3. Scoop packages ─────────────────────────────────────────────────────
# Windows-side binaries. `zsh` itself comes from MSYS2 (step 4) — we don't
# try to run zsh under native Windows.
# `scoop install` is itself idempotent: it prints "already installed" and
# exits 0 when the package is present, so we don't need a pre-check.
$scoopPackages = @(
    'git', 'chezmoi', 'neovim', 'lazygit', 'delta', 'starship',
    'fzf', 'ripgrep', 'fd', 'bat', 'eza', 'zoxide',
    'gh', 'jq', 'yq', 'mise', 'atuin',
    'msys2', 'wezterm',
    'JetBrains-Mono-NF'    # nerd-fonts bucket: registers the Nerd Font variant
)

Write-Step 'Scoop packages'
foreach ($p in $scoopPackages) {
    scoop install $p
}

# ── 4. MSYS2 package install ──────────────────────────────────────────────
# scoop installs msys2 under ~/scoop/apps/msys2/current. First run needs a
# pacman -Syu to build the initial DB; the msys2.exe launcher handles that
# if we just call it once. Then install zsh + helpers.
Write-Step 'MSYS2 — zsh + coreutils'
$msys2Bash = Join-Path $env:USERPROFILE 'scoop\apps\msys2\current\usr\bin\bash.exe'
if (-not (Test-Path $msys2Bash)) {
    Write-Err "MSYS2 bash not found at $msys2Bash — was `scoop install msys2` successful?"
    exit 1
}

# Run an MSYS2 command. We set MSYSTEM=MSYS for the pacman context (packages
# are installed into the MSYS runtime) and --login so /etc/profile sets up
# the environment correctly.
function Invoke-Msys2 {
    param([string]$Cmd)
    & $msys2Bash --login -c $Cmd
    if ($LASTEXITCODE -ne 0) {
        throw "MSYS2 command failed (exit $LASTEXITCODE): $Cmd"
    }
}

Invoke-Msys2 'pacman -Syu --noconfirm || true'   # first sync may ask to restart
Invoke-Msys2 'pacman -S --noconfirm --needed zsh git curl coreutils grep sed tar unzip'

# win32yank — clipboard bridge used by neovim inside MSYS2. If scoop has
# one, great; otherwise MSYS2 provides wl-clipboard-equivalent handling
# via the built-in clip.exe passthrough on Windows.
if (-not (Test-Cmd win32yank)) {
    scoop install win32yank 2>$null
    if (-not $?) { Write-Warn 'win32yank not in scoop — clipboard in nvim may fall back to clip.exe' }
}

# ── 5. chezmoi init --apply ───────────────────────────────────────────────
Write-Step "chezmoi init --apply $RepoUrl"
$chezmoiStateDir = Join-Path $env:USERPROFILE '.local\share\chezmoi'
$chezmoiCfgDir   = Join-Path $env:USERPROFILE '.config\chezmoi'
if ((Test-Path $chezmoiStateDir) -or (Test-Path $chezmoiCfgDir)) {
    chezmoi apply --verbose
}
else {
    chezmoi init --apply $RepoUrl
}

# ── 6. Post-install ───────────────────────────────────────────────────────
Write-Step 'done'
Write-Ok 'open WezTerm — it will launch MSYS2 zsh and load the dotfiles.'
Write-Ok 'then run: claude auth login'
Write-Warn 'If this was a first install, reboot once to make sure PATH + font cache are refreshed.'
