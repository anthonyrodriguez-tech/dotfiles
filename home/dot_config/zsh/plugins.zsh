# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : zinit plugin manager — installs itself on first run, then pulls
#         the four plugins that make zsh feel modern.
# WHERE : home/dot_config/zsh/plugins.zsh  →  ~/.config/zsh/plugins.zsh
# WHY   : zinit is fast, no-config, and copes well with the sourcing-order
#         constraint between zsh-completions, compinit, and the late
#         widget-wrapping plugins (fzf-tab, autosuggestions, syntax-highlighting).
# ─────────────────────────────────────────────────────────────────────────────

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Bootstrap on first run — silent unless something goes wrong.
if [[ ! -d "$ZINIT_HOME" ]]; then
    print -P "%F{33}>>> Installing zinit (first run)…%f"
    if ! command -v git >/dev/null 2>&1; then
        print -P "%F{160}>>> git is required to bootstrap zinit; aborting plugin load.%f"
        return 0
    fi
    mkdir -p "${ZINIT_HOME:h}"
    if git clone --quiet --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
        print -P "%F{33}>>> zinit installed.%f"
    else
        print -P "%F{160}>>> zinit clone failed; skipping plugin load.%f"
        return 0
    fi
fi

source "$ZINIT_HOME/zinit.zsh"

# ── Plugin order matters ──────────────────────────────────────────────────
# 1. zsh-completions adds completion functions to $fpath. Must come before compinit.
zinit light zsh-users/zsh-completions

# 2. compinit — picks up everything in $fpath, including the additions above.
#    Daily check pattern: full security scan once per 24h, cached -C the rest
#    of the time. ZSH_COMPDUMP is set in completion.zsh.
if [[ -n "${ZSH_COMPDUMP}"(#qN.mh+24) ]]; then
    compinit -d "$ZSH_COMPDUMP"
else
    compinit -C -d "$ZSH_COMPDUMP"
fi

# 3. fzf-tab — replaces the default completion menu with an fzf picker.
#    Loads after compinit so it can hook the existing widgets.
zinit light Aloxaf/fzf-tab

# 4. autosuggestions — ghost-text history-based suggestions.
zinit light zsh-users/zsh-autosuggestions

# 5. syntax-highlighting — wraps every widget; MUST be the very last plugin.
zinit light zsh-users/zsh-syntax-highlighting
