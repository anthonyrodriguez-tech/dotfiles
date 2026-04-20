# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : shell aliases. Modern-tool aliases are guarded with `command -v`
#         so the same file works on MSYS2 (no eza/zoxide/bat).
# WHERE : home/dot_config/zsh/aliases.zsh  →  ~/.config/zsh/aliases.zsh
# WHY   : One source of truth for short commands. Anything machine-specific
#         goes in ~/.config/zsh/local.zsh, sourced last by .zshrc.
# ─────────────────────────────────────────────────────────────────────────────

# ── git ───────────────────────────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gc='git commit'
alias gca='git commit --amend'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gst='git stash'
alias lg='lazygit'

# ── editor ────────────────────────────────────────────────────────────────
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# ── tmux (only where installed; MSYS2 typically lacks it) ─────────────────
if command -v tmux >/dev/null 2>&1; then
    alias t='tmux'
    alias ta='tmux attach -t'
    alias tn='tmux new -s'
    alias tl='tmux list-sessions'
    alias tk='tmux kill-session -t'
fi

# ── docker / kubernetes / terraform / claude ──────────────────────────────
alias d='docker'
alias dc='docker compose'
alias k='kubectl'
alias tf='terraform'
alias cc='claude'

# ── ls replacements ───────────────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --git --group-directories-first'
    alias la='eza -la --git --group-directories-first'
    alias lt='eza --tree --level=2 --group-directories-first'
elif command -v lsd >/dev/null 2>&1; then
    alias ls='lsd --group-directories-first'
    alias ll='lsd -l --group-directories-first'
    alias la='lsd -la --group-directories-first'
fi

# ── cat replacement ───────────────────────────────────────────────────────
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
    # Debian/Ubuntu ship bat as `batcat` to avoid a name clash.
    alias bat='batcat'
    alias cat='batcat --paging=never'
fi

# ── fd alias on Debian/Ubuntu (where the binary is `fdfind`) ──────────────
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi

# ── chezmoi (we use it daily) ─────────────────────────────────────────────
alias cz='chezmoi'
alias czd='chezmoi diff'
alias cza='chezmoi apply -v'
alias cze='chezmoi edit'
alias czcd='chezmoi cd'
