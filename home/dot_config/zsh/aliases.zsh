# Aliases. Modern-tool aliases guarded with `command -v` so the file is
# safe on a fresh shell where binaries may still be missing.

# git
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

# editor
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# ls → eza
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --git --group-directories-first'
    alias la='eza -la --git --group-directories-first'
    alias lt='eza --tree --level=2 --group-directories-first'
fi

# cat → bat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
fi

# Debian/Ubuntu ships `fd` as `fdfind`.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi

# chezmoi
alias cz='chezmoi'
alias czd='chezmoi diff'
alias cza='chezmoi apply -v'
alias cze='chezmoi edit'
alias czcd='chezmoi cd'

# claude
alias cc='claude'
