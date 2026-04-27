# Windows entry point -- Scoop + chezmoi. One file, no TUI.
#
#   irm https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.ps1 | iex
#   .\scripts\install.ps1

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

# PS 5.1 vs PS 7 module-path collision (mixed corporate images): strip PS7
# paths so 5.1 stays in its own lane. No-op on hosts without PS7.
if ($PSVersionTable.PSVersion.Major -lt 6) {
    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object {
        $_ -and $_ -notmatch '\\PowerShell\\7\b' -and $_ -notmatch '\\Modules-PWSH'
    }) -join ';'
}
try { Import-Module Microsoft.PowerShell.Security -Force -ErrorAction Stop } catch { }

$RepoUrl   = if ($env:DOTFILES_REPO)   { $env:DOTFILES_REPO }   else { 'https://github.com/tony/dotfiles.git' }
$Branch    = if ($env:DOTFILES_BRANCH) { $env:DOTFILES_BRANCH } else { 'main' }
$SourceDir = Join-Path $env:USERPROFILE '.local\share\chezmoi'

function Write-Step {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Coloured bootstrap output')]
    param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Blue
}
function Write-Ok {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Coloured bootstrap output')]
    param([string]$Msg) Write-Host "  v $Msg" -ForegroundColor Green
}
function Write-Warn {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Coloured bootstrap output')]
    param([string]$Msg) Write-Host "  ! $Msg" -ForegroundColor Yellow
}
function Write-Err {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Coloured bootstrap output')]
    param([string]$Msg) Write-Host "  x $Msg" -ForegroundColor Red
}
function Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Invoke-RemoteInstaller {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'Upstream Scoop / Claude / omp installers are designed for iex')]
    param([string]$Uri)
    Invoke-RestMethod -Uri $Uri | Invoke-Expression
}

function Read-WithDefault {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Interactive prompt')]
    param([string]$Label, [string]$Default = '')
    if ($Default) { Write-Host -NoNewline "$Label [$Default]: " -ForegroundColor Cyan }
    else          { Write-Host -NoNewline "${Label}: "          -ForegroundColor Cyan }
    $r = Read-Host
    if ([string]::IsNullOrWhiteSpace($r)) { $Default } else { $r }
}

# Refuse elevated runs -- Scoop must install user-scope.
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err 'Do not run this script as Administrator. Scoop must install under your user profile.'
    exit 1
}

try {
    if ((Get-ExecutionPolicy -Scope CurrentUser) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
        Write-Step 'Setting CurrentUser ExecutionPolicy to RemoteSigned (no admin needed)'
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }
} catch {
    Write-Warn "skipping execution-policy adjustment: $($_.Exception.Message.Split([Environment]::NewLine)[0])"
}

# ── 1. Proxy + identity prompts (skip if env already set) ────────────────
$proxyHttp  = if ($env:HTTP_PROXY)  { $env:HTTP_PROXY }  else { '' }
$proxyHttps = if ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } else { $proxyHttp }
if (-not $proxyHttp -and -not $proxyHttps) {
    $proxyHttp  = Read-WithDefault 'HTTP proxy URL (blank if none)'  ''
    $proxyHttps = Read-WithDefault 'HTTPS proxy URL (blank if none)' $proxyHttp
}
if ($proxyHttp)  { $env:HTTP_PROXY  = $proxyHttp;  $env:http_proxy  = $proxyHttp }
if ($proxyHttps) { $env:HTTPS_PROXY = $proxyHttps; $env:https_proxy = $proxyHttps }

$fullName = Read-WithDefault 'Full name'     $env:USERNAME
$email    = Read-WithDefault 'Email address' "$env:USERNAME@localhost"

# ── 2. Scoop ─────────────────────────────────────────────────────────────
Write-Step 'Scoop'
if (Test-Cmd scoop) { Write-Ok 'already installed' }
else { Invoke-RemoteInstaller 'https://get.scoop.sh' }
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
            [Environment]::GetEnvironmentVariable('PATH', 'Machine')

Write-Step 'Scoop buckets'
foreach ($b in @('main', 'extras', 'nerd-fonts')) {
    scoop bucket add $b 2>$null
}

# ── 3. Stack KISS ────────────────────────────────────────────────────────
$stack = @(
    'git', 'chezmoi', 'pwsh', 'wezterm', 'neovim', 'lazygit', 'starship',
    'zoxide', 'eza', 'fzf', 'ripgrep', 'fd', 'bat', 'delta', 'gh',
    'jq', 'yq', 'JetBrainsMono-NF'
)
Write-Step 'Scoop packages'
foreach ($p in $stack) { scoop install $p }

# PSReadLine (predictive history, syntax highlighting) + PSFzf (Ctrl-R/T).
# Install only if missing; -SkipPublisherCheck handles signed-module quirks
# on bare PS 5.1.
foreach ($mod in @('PSReadLine', 'PSFzf')) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Install-Module -Name $mod -Force -Scope CurrentUser -SkipPublisherCheck
    }
}

# ── 4. Claude Code (native installer) ────────────────────────────────────
Write-Step 'Claude Code'
if (Test-Cmd claude) { Write-Ok 'already installed' }
else { Invoke-RemoteInstaller 'https://claude.ai/install.ps1' }

# ── 5. oh-my-pi (omp) ────────────────────────────────────────────────────
Write-Step 'oh-my-pi'
if (Test-Cmd omp) { Write-Ok 'already installed' }
else { Invoke-RemoteInstaller 'https://raw.githubusercontent.com/can1357/oh-my-pi/main/scripts/install.ps1' }

# ── 6. Pre-write chezmoi.toml so init does not prompt ────────────────────
$chezmoiCfg = Join-Path $env:USERPROFILE '.config\chezmoi'
New-Item -ItemType Directory -Force -Path $chezmoiCfg | Out-Null
$cfgBody = @"
[data]
    name        = "$fullName"
    email       = "$email"
    proxy_http  = "$proxyHttp"
    proxy_https = "$proxyHttps"
"@
Set-Content -Path (Join-Path $chezmoiCfg 'chezmoi.toml') -Value $cfgBody -Encoding utf8

# ── 7. chezmoi init --apply ──────────────────────────────────────────────
Write-Step "chezmoi init --apply $RepoUrl"
chezmoi init --apply $RepoUrl

Write-Step 'done'
Write-Ok 'open WezTerm -- zsh-like prompt via PowerShell + starship.'
Write-Ok 'claude  (first launch prompts for browser login)'
Write-Ok 'omp     (configure providers via /login)'
Write-Warn 'If this was a first install, open a new terminal so PATH + font cache refresh.'
