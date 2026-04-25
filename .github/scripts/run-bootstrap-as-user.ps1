# ─────────────────────────────────────────────────────────────────────────
# WHAT  : CI helper — runs bootstrap-windows.ps1 with the chezmoi step
#         disabled, tees stdout+stderr to a log the parent step reads.
# WHERE : .github/scripts/run-bootstrap-as-user.ps1
# WHY   : Lives in its own .ps1 file (rather than inline in YAML) because
#         here-strings full of $-prefixed PowerShell vars and PS-escaped
#         backticks don't survive YAML's block-scalar parsing.
# ─────────────────────────────────────────────────────────────────────────

param(
    [Parameter(Mandatory)] [string] $BootstrapPath,
    [Parameter(Mandatory)] [string] $LogPath
)

$ErrorActionPreference = 'Stop'
$env:DOTFILES_BOOTSTRAP_SKIP_CHEZMOI = '1'
& $BootstrapPath *>&1 | Tee-Object -FilePath $LogPath
exit $LASTEXITCODE
