# $PATH composition. Unique-array so re-sourcing does not duplicate.

typeset -U path PATH

path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    $path
)

case "$DOTFILES_OS" in
    linux)
        [[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
        [[ -d "$HOME/go/bin" ]]     && path=("$HOME/go/bin" $path)
        ;;
    windows)
        [[ -d "$HOME/scoop/shims" ]] && path=("$HOME/scoop/shims" $path)
        ;;
esac
