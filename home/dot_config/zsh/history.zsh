# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : zsh history config — file location, size, dedup behaviour.
# WHERE : home/dot_config/zsh/history.zsh  →  ~/.config/zsh/history.zsh
# WHY   : Default $HISTFILE lives at ~/.zsh_history. We move it under
#         $XDG_STATE_HOME so $HOME stays clean and so backups can target a
#         single state directory.
# ─────────────────────────────────────────────────────────────────────────────

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000      # in-memory entries
SAVEHIST=50000      # on-disk entries

[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

setopt EXTENDED_HISTORY        # store timestamp + duration
setopt INC_APPEND_HISTORY      # write each command immediately
setopt SHARE_HISTORY           # cross-session live sharing
setopt HIST_IGNORE_DUPS        # don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS    # purge older duplicates of a re-run command
setopt HIST_IGNORE_SPACE       # `   secret` (leading space) → not recorded
setopt HIST_REDUCE_BLANKS      # collapse internal whitespace
setopt HIST_VERIFY             # `!!` / `!$` expand on Enter, don't auto-run
