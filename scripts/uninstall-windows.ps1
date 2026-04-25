# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Windows uninstall — reverses bootstrap-windows.ps1.
# WHERE : scripts/uninstall-windows.ps1
# WHY   : Clean recovery from a broken bootstrap, or full removal when the
#         laptop is being handed back. Non-admin, mirrors the same packages
#         and tools the bootstrap installs.
#
# Usage (PowerShell, no admin):
#   .\scripts\uninstall-windows.ps1            # remove our scoop apps + chezmoi state, keep scoop itself
#   .\scripts\uninstall-windows.ps1 -Full      # also remove scoop entirely (~\scoop deleted)
#   .\scripts\uninstall-windows.ps1 -Force     # skip the confirmation prompt
#
# Does NOT delete dotfiles already deployed to %USERPROFILE% (e.g. .zshrc) —
# chezmoi purge only removes the source repo + chezmoi config. Remove
# deployed files by hand if you want a fully clean profile.
# ─────────────────────────────────────────────────────────────────────────

#Requires -Version 5.1
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Intentional: colorised output in an uninstall script')]
[CmdletBinding()]
param(
    [switch]$Full,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "  v $Msg"  -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  ! $Msg"  -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "  x $Msg"  -ForegroundColor Red }

function Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# Same elevation guard as bootstrap — scoop state lives under %USERPROFILE%.
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err 'Do not run this script as Administrator.'
    exit 1
}

if (-not $Force) {
    $scope = if ($Full) { 'Scoop apps + chezmoi state + scoop itself (~\scoop will be deleted)' } else { 'Scoop apps + chezmoi state (scoop itself preserved)' }
    Write-Warn "This will remove: $scope"
    $reply = Read-Host 'Continue? (y/N)'
    if ($reply -notmatch '^[yY]') { Write-Ok 'aborted'; exit 0 }
}

# ── 1. Stop MSYS2 + Claude processes that would hold files open ───────────
Write-Step 'Stopping background processes'
$scoopRoot = Join-Path $env:USERPROFILE 'scoop'
$claudeBin = Join-Path $env:USERPROFILE '.local\bin'

$stuck = Get-Process | Where-Object {
    $_.Path -and (
        $_.Path.StartsWith($scoopRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $_.Path.StartsWith($claudeBin, [StringComparison]::OrdinalIgnoreCase)
    )
}
foreach ($p in $stuck) { Write-Warn ("stopping {0} (pid {1})" -f $p.ProcessName, $p.Id) }
$stuck | Stop-Process -Force -ErrorAction SilentlyContinue

Get-Process bash, mintty, gpg-agent, dirmngr, pacman, msys2, claude, wezterm-gui, nvim -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# ── 2. chezmoi purge — source dir + chezmoi config ────────────────────────
Write-Step 'chezmoi purge'
if (Test-Cmd chezmoi) {
    chezmoi purge --force 2>&1 | Out-Host
    Write-Ok 'chezmoi state removed'
}
else {
    foreach ($d in @('.local\share\chezmoi', '.config\chezmoi', '.cache\chezmoi')) {
        $path = Join-Path $env:USERPROFILE $d
        if (Test-Path $path) {
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $path
            Write-Ok "removed $path"
        }
    }
}

# ── 3. Claude Code (native installer) ─────────────────────────────────────
Write-Step 'Claude Code'
$claudeExe = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
if (Test-Path $claudeExe) {
    Remove-Item -Force -ErrorAction SilentlyContinue $claudeExe
    Write-Ok 'removed claude.exe'
}
foreach ($d in @('.claude', '.claude.json')) {
    $path = Join-Path $env:USERPROFILE $d
    if (Test-Path $path) { Write-Warn "kept $path (contains your settings/history) — delete manually if desired" }
}

# ── 4. Scoop apps installed by bootstrap ──────────────────────────────────
Write-Step 'Scoop packages'
$scoopPackages = @(
    'JetBrainsMono-NF', 'wezterm', 'msys2',
    'atuin', 'mise', 'yq', 'jq', 'gh',
    'zoxide', 'eza', 'bat', 'fd', 'ripgrep', 'fzf',
    'starship', 'delta', 'lazygit', 'neovim', 'chezmoi', 'git',
    'win32yank'
)

if (Test-Cmd scoop) {
    foreach ($p in $scoopPackages) {
        scoop uninstall $p 2>&1 | Out-Null
    }
    Write-Ok 'scoop apps removed'
}
else {
    Write-Warn 'scoop not on PATH — skipping per-package uninstall'
}

# msys2 leaves its app dir behind if anything was still locked at uninstall time
$msys2Root = Join-Path $env:USERPROFILE 'scoop\apps\msys2'
if (Test-Path $msys2Root) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $msys2Root
    if (-not (Test-Path $msys2Root)) { Write-Ok 'cleaned up scoop\apps\msys2' }
    else { Write-Warn "could not remove $msys2Root — close any open terminals and rerun" }
}

# ── 5. Optional: nuke scoop itself ────────────────────────────────────────
if ($Full) {
    Write-Step 'Removing scoop'
    if (Test-Cmd scoop) { scoop uninstall scoop 2>&1 | Out-Host }
    if (Test-Path $scoopRoot) {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $scoopRoot
        if (Test-Path $scoopRoot) { Write-Warn "scoop dir not fully removed: $scoopRoot" }
        else { Write-Ok 'scoop removed' }
    }
    [Environment]::SetEnvironmentVariable('SCOOP', $null, 'User')
}

Write-Step 'done'
Write-Ok 'reboot recommended so PATH and font cache refresh'
if (-not $Full) { Write-Warn 'scoop preserved — re-run with -Full to remove it as well' }
