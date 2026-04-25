# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : $PATH composition + per-OS package-manager activation.
# WHERE : home/dot_config/zsh/path.zsh  →  ~/.config/zsh/path.zsh
# WHY   : One file owns the $PATH order. `typeset -U path PATH` keeps entries
#         unique even on repeated sourcing (re-runs of `exec zsh`).
# ─────────────────────────────────────────────────────────────────────────────

# Make $path / $PATH unique-array (zsh-only); preserves first occurrence.
typeset -U path PATH

# User-local bins go to the front so personal scripts shadow system ones.
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    $path
)

case "$DOTFILES_OS" in
    linux)
        # Common per-language bin dirs — only prepend if they exist, to
        # avoid bloating $PATH on minimal containers.
        [[ -d "$HOME/.cargo/bin" ]]      && path=("$HOME/.cargo/bin" $path)
        [[ -d "$HOME/.local/share/go/bin" ]] && path=("$HOME/.local/share/go/bin" $path)
        [[ -d "$HOME/go/bin" ]]          && path=("$HOME/go/bin" $path)
        ;;
    windows)
        # MSYS2's login shell does NOT inherit the Windows PATH reliably.
        # Explicitly prepend the Scoop shim directory so nvim, starship,
        # lazygit, etc. are available inside the terminal.
        [[ -d "$HOME/scoop/shims" ]] && path=("$HOME/scoop/shims" $path)
        ;;
esac

# mise (universal version manager) — must come AFTER all static $PATH edits
# so its shims sit at the front and shadow any system `node`/`python`.
# On Windows/MSYS2, mise outputs Windows-style paths (C:\...) that zsh
# cannot parse, so skip activation there.
if [[ "$DOTFILES_OS" != windows ]] && command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi
