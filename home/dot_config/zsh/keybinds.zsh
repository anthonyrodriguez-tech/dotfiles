# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : keymap config — emacs base + history-prefix search + edit-line.
# WHERE : home/dot_config/zsh/keybinds.zsh  →  ~/.config/zsh/keybinds.zsh
# WHY   : Sourced AFTER plugins so we can override widgets that
#         autosuggestions/syntax-highlighting may have wrapped (notably
#         the up/down arrows).
#
# Note on Ctrl-R: not bound here. fzf installs its own Ctrl-R / Ctrl-T /
# Alt-C bindings in integrations.zsh, which runs after this file.
# ─────────────────────────────────────────────────────────────────────────────

bindkey -e   # emacs keymap (Ctrl-A start, Ctrl-E end, Ctrl-W kill word…)

# ── History prefix-search on Up/Down/Ctrl-P/Ctrl-N ────────────────────────
# Type `git ` then Up → only history entries starting with `git ` cycle.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Terminal-emulator escape sequences for Up/Down arrows.
bindkey '^[[A'    up-line-or-beginning-search
bindkey '^[[B'    down-line-or-beginning-search
bindkey '^[OA'    up-line-or-beginning-search   # alternate (some terminals)
bindkey '^[OB'    down-line-or-beginning-search
bindkey '^P'      up-line-or-beginning-search
bindkey '^N'      down-line-or-beginning-search

# ── Word jumps on Ctrl-Left / Ctrl-Right ──────────────────────────────────
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word                  # macOS: Alt-Right
bindkey '^[[1;3D' backward-word                 # macOS: Alt-Left

# ── Line edits ────────────────────────────────────────────────────────────
bindkey '^U' backward-kill-line                 # default kills whole line; we want left half
bindkey '^K' kill-line                          # right half

# Open the current command line in $EDITOR (Ctrl-X Ctrl-E).
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
