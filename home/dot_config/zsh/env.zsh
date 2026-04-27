# Interactive-shell env vars. ~/.zshenv stays minimal; this is the place
# for vars only useful in interactive sessions.

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export MANPAGER='nvim +Man!'
export LESS='-R --use-color -Dd+r$Du+b'

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"

if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

export BAT_THEME='Catppuccin Mocha'
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"

export LESSHISTFILE="$XDG_STATE_HOME/less/history"
[[ -d "${LESSHISTFILE:h}" ]] || mkdir -p "${LESSHISTFILE:h}"
