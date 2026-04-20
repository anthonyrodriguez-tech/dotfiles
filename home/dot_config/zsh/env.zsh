# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : interactive-shell env vars (editor, pager, locale, tool configs).
# WHERE : home/dot_config/zsh/env.zsh  →  ~/.config/zsh/env.zsh
# WHY   : .zshenv is intentionally tiny; vars only useful in interactive
#         shells live here (avoids polluting cron/non-interactive scripts).
# ─────────────────────────────────────────────────────────────────────────────

# Editors / pagers
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export MANPAGER='nvim +Man!'
export LESS='-R --use-color -Dd+r$Du+b'

# Locale — fallback only; corporate machines often ship sane defaults.
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"

# fzf — prefer fd if available (much faster than find, respects .gitignore).
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

# bat — Catppuccin theme registered by `bat cache --build` (Phase 6 doc).
export BAT_THEME='Catppuccin Mocha'

# ripgrep — config file at $XDG_CONFIG_HOME/ripgrep/ripgreprc (Phase 2.5).
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"

# Less history at the right spot.
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
[[ -d "${LESSHISTFILE:h}" ]] || mkdir -p "${LESSHISTFILE:h}"
