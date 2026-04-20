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
    mac)
        # Apple Silicon (M-series) ships brew under /opt/homebrew; Intel
        # macs under /usr/local. Pick whichever exists.
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ;;
    linux)
        # Common per-language bin dirs — only prepend if they exist, to
        # avoid bloating $PATH on minimal containers.
        [[ -d "$HOME/.cargo/bin" ]]      && path=("$HOME/.cargo/bin" $path)
        [[ -d "$HOME/.local/share/go/bin" ]] && path=("$HOME/.local/share/go/bin" $path)
        [[ -d "$HOME/go/bin" ]]          && path=("$HOME/go/bin" $path)
        ;;
    windows)
        # MSYS2 sets up its own /usr/bin layout; Scoop apps live under
        # %USERPROFILE%/scoop/shims, which Scoop already exports. Nothing
        # to add here. Documented for the next reader.
        :
        ;;
esac

# mise (universal version manager) — must come AFTER all static $PATH edits
# so its shims sit at the front and shadow any system `node`/`python`.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi
