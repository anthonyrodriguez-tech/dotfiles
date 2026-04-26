# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Windows-side wrapper for the gum TUI. Delegates to MSYS2 bash
#         + scripts/common/tui.sh — no logic duplicated.
# WHERE : home/dot_local/bin/dotfiles-config.ps1
#         → ~/.local/bin/dotfiles-config.ps1  (deployed by chezmoi)
# WHY   : tui.sh is portable POSIX bash. On Windows we already have MSYS2
#         from the bootstrap, so reusing it keeps a single source of truth.
#
# Usage:
#   dotfiles-config.ps1            # re-prompt + chezmoi apply
#   dotfiles-config.ps1 -NoApply   # only rewrite chezmoi.toml
# ─────────────────────────────────────────────────────────────────────────

#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$NoApply
)

$ErrorActionPreference = 'Stop'

$msys2Bash = Join-Path $env:USERPROFILE 'scoop\apps\msys2\current\usr\bin\bash.exe'
if (-not (Test-Path $msys2Bash)) {
    Write-Host '  x MSYS2 bash not found — re-run scripts/install.ps1 first.' -ForegroundColor Red
    exit 1
}

$tui = '$HOME/.local/share/chezmoi/scripts/common/tui.sh'
$flag = if ($NoApply) { '--no-bootstrap' } else { '' }

& $msys2Bash --login -c "set -e; . $tui; tui::run $flag"
exit $LASTEXITCODE
