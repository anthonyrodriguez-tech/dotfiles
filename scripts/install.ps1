# ─────────────────────────────────────────────────────────────────────────
# WHAT  : single Windows entry point. Same role as install.sh on Linux.
# WHERE : scripts/install.ps1
# WHY   : "Plug & Play" promise — one curl-pipe-friendly URL the user
#         can run from PowerShell to bootstrap everything.
#
# Usage (PowerShell, no admin):
#   irm https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.ps1 | iex
#   .\scripts\install.ps1
# ─────────────────────────────────────────────────────────────────────────

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

$RepoUrl   = if ($env:DOTFILES_REPO)   { $env:DOTFILES_REPO }   else { 'https://github.com/tony/dotfiles.git' }
$Branch    = if ($env:DOTFILES_BRANCH) { $env:DOTFILES_BRANCH } else { 'main' }
$SourceDir = Join-Path $env:USERPROFILE '.local\share\chezmoi'

function Write-Step {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Coloured bootstrap output')]
    param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue
}
function Write-Err {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Coloured bootstrap output')]
    param([string]$Msg) Write-Host "  x $Msg" -ForegroundColor Red
}

function Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# Scoop's official one-liner is `irm get.scoop.sh | iex` — there is no
# alternative bootstrap path. Wrap it so the rule suppression is scoped.
function Invoke-RemoteInstaller {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'Upstream Scoop installer is designed for iex')]
    param([string]$Uri)
    Invoke-RestMethod -Uri $Uri | Invoke-Expression
}

# ── 1. Resolve script dir (local checkout vs irm-pipe) ───────────────────
$ScriptDir = $null
if ($PSScriptRoot) { $ScriptDir = $PSScriptRoot }

if (-not $ScriptDir -or -not (Test-Path (Join-Path $ScriptDir 'bootstrap-windows.ps1'))) {
    if (-not (Test-Path (Join-Path $SourceDir '.git'))) {
        if (-not (Test-Cmd git)) {
            # Bootstrap git via Scoop (which we'll need anyway).
            if (-not (Test-Cmd scoop)) {
                Write-Step 'installing scoop (needed to fetch git)'
                Invoke-RemoteInstaller 'https://get.scoop.sh'
                $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
                            [Environment]::GetEnvironmentVariable('PATH', 'Machine')
            }
            Write-Step 'installing git via scoop'
            scoop install git
        }
        Write-Step "cloning $RepoUrl -> $SourceDir"
        New-Item -ItemType Directory -Force -Path (Split-Path $SourceDir) | Out-Null
        git clone --depth=1 --branch $Branch $RepoUrl $SourceDir
    }
    else {
        Write-Step "repo already at $SourceDir — pulling latest"
        git -C $SourceDir pull --ff-only --quiet
    }
    $ScriptDir = Join-Path $SourceDir 'scripts'
}

# ── 2. Dispatch to the Windows bootstrap ──────────────────────────────────
$bootstrap = Join-Path $ScriptDir 'bootstrap-windows.ps1'
if (-not (Test-Path $bootstrap)) {
    Write-Err "bootstrap-windows.ps1 not found at $bootstrap"
    exit 1
}

& $bootstrap
