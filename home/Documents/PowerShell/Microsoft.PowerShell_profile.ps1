# ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1 — interactive
# PowerShell entry point. Same role as ~/.config/zsh/.zshrc on Linux.
# Loaded by both PS 7 (pwsh) and PS 5.1 (powershell.exe via stub in
# WindowsPowerShell/).

# ── PSReadLine: predictive history (= zsh-autosuggestions) + colours ─────
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -HistoryNoDuplicates -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
}

# ── starship — universal prompt ───────────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# ── zoxide — `cd` becomes the smart jumper (`cdi` opens the fzf picker) ──
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# ── fzf — Ctrl-R / Ctrl-T bindings via PSFzf ─────────────────────────────
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ── env vars (mirror env.zsh) ────────────────────────────────────────────
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'
$env:BAT_THEME = 'Catppuccin Mocha'

# ── Aliases (mirror aliases.zsh) ─────────────────────────────────────────
# git
function gs  { git status @args }
function gd  { git diff @args }
function gds { git diff --staged @args }
function gco { git checkout @args }
function gsw { git switch @args }
function gp  { git push @args }
function gpl { git pull @args }
function gl  { git log --oneline --graph --decorate @args }
function gla { git log --oneline --graph --decorate --all @args }
function gcm { git commit -m @args }
Set-Alias g  git
Set-Alias lg lazygit

# editor
Set-Alias v   nvim
Set-Alias vi  nvim
Set-Alias vim nvim

# ls -> eza (drop the built-in `ls` alias for Get-ChildItem first)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --group-directories-first @args }
    function ll { eza -l --git --group-directories-first @args }
    function la { eza -la --git --group-directories-first @args }
    function lt { eza --tree --level=2 --group-directories-first @args }
}

# bat -> cat
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    function cat { bat --paging=never @args }
}

# chezmoi
Set-Alias cz chezmoi
function czd  { chezmoi diff @args }
function cza  { chezmoi apply -v @args }
function cze  { chezmoi edit @args }
function czcd { chezmoi cd @args }

# claude
Set-Alias cc claude

# Per-machine overrides — never tracked.
$localProfile = Join-Path (Split-Path $PROFILE) 'local.ps1'
if (Test-Path $localProfile) { . $localProfile }
