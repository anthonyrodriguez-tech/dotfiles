# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : completion config (cache path + zstyles only — compinit itself
#         fires later, in plugins.zsh, once zsh-completions is in fpath).
# WHERE : home/dot_config/zsh/completion.zsh  →  ~/.config/zsh/completion.zsh
# WHY   : compinit must run AFTER plugins that add to fpath. Splitting
#         "config" (here) from "execution" (plugins.zsh) lets the loader
#         in .zshrc keep a clean linear order.
# ─────────────────────────────────────────────────────────────────────────────

# Cache lives under XDG; one dump per zsh version (changes between minor
# releases can break a stale dump).
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-${ZSH_VERSION}"
[[ -d "${ZSH_COMPDUMP:h}" ]] || mkdir -p "${ZSH_COMPDUMP:h}"

# Pre-load compinit so plugins.zsh can call it without re-autoloading.
autoload -Uz compinit

# ── zstyles ────────────────────────────────────────────────────────────────
# menu-select: arrow-key navigable completion menu.
zstyle ':completion:*' menu select

# Case-insensitive + partial matching: `dl<TAB>` → `Downloads`, `tom<TAB>` → `Documents/tomes`.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Colour completion list using $LS_COLORS.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group results by category and label each group.
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings'     format 'No matches: %d'

# Use the cache for slow completions (apt/pacman/scoop/git).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/compcache"
[[ -d "$XDG_CACHE_HOME/zsh/compcache" ]] || mkdir -p "$XDG_CACHE_HOME/zsh/compcache"
