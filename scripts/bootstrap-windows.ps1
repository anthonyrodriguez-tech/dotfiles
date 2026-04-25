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
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '', Justification = 'Decorative ASCII-art in comments; file is UTF-8 without BOM by design')]
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

function Invoke-WithRetry {
    param([scriptblock]$Action, [int]$MaxAttempts = 3, [int]$DelaySec = 10)
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try { & $Action; return } catch {
            if ($i -eq $MaxAttempts) { throw }
            Write-Warn "attempt $i/$MaxAttempts failed — retrying in ${DelaySec}s"
            Start-Sleep -Seconds $DelaySec
        }
    }
}

function Repair-ScoopBucket {
    param([string]$Name)
    $bucketPath = Join-Path $env:USERPROFILE "scoop\buckets\$Name"
    if ((Test-Path $bucketPath) -and -not (Test-Path (Join-Path $bucketPath '.git'))) {
        Write-Warn "bucket $Name is corrupted — removing and re-adding"
        scoop bucket rm $Name 2>$null
    }
    scoop bucket add $Name 2>$null
    Write-Ok "bucket $Name"
}

# A previous failed scoop install can leave a partial msys2 dir whose files
# are held open by stray bash/mintty/gpg-agent/dirmngr processes. Scoop then
# loops forever ("Couldn't remove ... it may be in use"). Detect that state,
# kill the holders, and wipe the dir so the next `scoop install msys2` works.
function Repair-Msys2Install {
    $msys2Root = Join-Path $env:USERPROFILE 'scoop\apps\msys2'
    if (-not (Test-Path $msys2Root)) { return }
    if (Test-Path (Join-Path $msys2Root 'current\usr\bin\bash.exe')) { return }

    Write-Warn 'MSYS2 install looks partial — clearing locks before retry'

    $stuck = Get-Process | Where-Object {
        $_.Path -and $_.Path.StartsWith($msys2Root, [StringComparison]::OrdinalIgnoreCase)
    }
    foreach ($p in $stuck) {
        Write-Warn ("stopping {0} (pid {1})" -f $p.ProcessName, $p.Id)
    }
    $stuck | Stop-Process -Force -ErrorAction SilentlyContinue

    # Daemons whose .Path may be null but still hold locks
    Get-Process bash, sh, zsh, mintty, gpg-agent, dirmngr, pacman, msys2 `
        -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 1
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $msys2Root
    if (-not (Test-Path $msys2Root)) {
        Write-Ok 'cleaned up partial MSYS2 install'
        return
    }

    # Rename-then-delete. NTFS lets you rename a dir even when files inside
    # are locked (Defender scan, Search Indexer, a stray editor with a handle
    # we couldn't trace), which frees the canonical path for scoop's fresh
    # install. The shadow dir is best-effort: if its files are still locked
    # we leave it for the user to delete after a reboot rather than letting
    # scoop hang on the locked path.
    $shadow = "$msys2Root.broken-$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    try {
        [IO.Directory]::Move($msys2Root, $shadow)
        Write-Ok "renamed locked dir to $shadow — fresh install can proceed"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $shadow
        if (Test-Path $shadow) {
            Write-Warn "$shadow still has locked files — delete it manually after a reboot"
        }
        return
    }
    catch {
        Write-Err "Cannot reclaim $msys2Root — even rename failed ($($_.Exception.Message))."
        Write-Err 'Close ALL WezTerm / VS Code / Cursor / nvim / claude windows and re-run, or reboot.'
        exit 1
    }
}

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
    Repair-ScoopBucket $b
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
    'JetBrainsMono-NF'     # nerd-fonts bucket: registers the Nerd Font variant
)

Write-Step 'Scoop packages'
foreach ($p in $scoopPackages) {
    if ($p -eq 'msys2') { Repair-Msys2Install }
    Invoke-WithRetry { scoop install $p }
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

# First pass may kill its own process when msys2-runtime upgrades — that's
# expected behaviour. Swallow the error and run a second pass to finish.
try { Invoke-Msys2 'pacman -Syu --noconfirm' } catch {
    Write-Warn 'MSYS2 first-pass ended early (msys2-runtime upgrade) — running second pass'
}
Invoke-Msys2 'pacman -Syu --noconfirm'
Invoke-Msys2 'pacman -S --noconfirm --needed zsh git curl coreutils grep sed tar unzip'

# Point MSYS2 $HOME at the Windows profile directory so zsh finds the
# dotfiles that chezmoi deploys to %USERPROFILE% (e.g. .zshenv, .zshrc).
$nsswitch = Join-Path $env:USERPROFILE 'scoop\apps\msys2\current\etc\nsswitch.conf'
if (Test-Path $nsswitch) {
    (Get-Content $nsswitch) -replace 'db_home:\s+cygwin\b.*', 'db_home: windows' |
        Set-Content $nsswitch
    Write-Ok 'MSYS2 db_home set to windows'
}

# win32yank — clipboard bridge used by neovim inside MSYS2. If scoop has
# one, great; otherwise MSYS2 provides wl-clipboard-equivalent handling
# via the built-in clip.exe passthrough on Windows.
if (-not (Test-Cmd win32yank)) {
    scoop install win32yank 2>$null
    if (-not $?) { Write-Warn 'win32yank not in scoop — clipboard in nvim may fall back to clip.exe' }
}

# ── 5. Claude Code (native installer, replaces legacy `npm i -g`) ────────
Write-Step 'Claude Code (native installer)'
if (Test-Cmd claude) {
    Write-Ok 'already installed'
}
else {
    Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' | Invoke-Expression
}

# ── 6. chezmoi init --apply ───────────────────────────────────────────────
Write-Step "chezmoi init --apply $RepoUrl"
$chezmoiStateDir = Join-Path $env:USERPROFILE '.local\share\chezmoi'
$chezmoiCfgDir   = Join-Path $env:USERPROFILE '.config\chezmoi'
if ((Test-Path $chezmoiStateDir) -or (Test-Path $chezmoiCfgDir)) {
    chezmoi apply --verbose
}
else {
    chezmoi init --apply $RepoUrl
}

# ── 7. Post-install ───────────────────────────────────────────────────────
Write-Step 'done'
Write-Ok 'open WezTerm — it will launch MSYS2 zsh and load the dotfiles.'
Write-Ok 'then run: claude  (first launch prompts for browser login)'
Write-Warn 'If this was a first install, reboot once to make sure PATH + font cache are refreshed.'
