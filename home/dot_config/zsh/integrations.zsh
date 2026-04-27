# Tool integrations. Sourced LAST: starship owns the prompt, zoxide
# replaces `cd`, fzf installs Ctrl-R / Ctrl-T / Alt-C bindings, and the
# zsh plugin pair (autosuggestions + syntax-highlighting) wraps every
# widget — syntax-highlighting MUST come last to see the final state.

# starship — universal prompt.
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# zoxide — `cd` itself becomes the smart jumper (`cdi` for fzf picker).
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"

# fzf — keybinds + completion. Modern fzf ships `fzf --zsh`; older versions
# need per-distro install paths.
if command -v fzf >/dev/null 2>&1; then
    if _f="$(fzf --zsh 2>/dev/null)" && [[ -n "$_f" ]]; then
        eval "$_f"
    else
        for _f in \
            /usr/share/fzf/key-bindings.zsh \
            /usr/share/doc/fzf/examples/key-bindings.zsh \
            "$HOME/.fzf/shell/key-bindings.zsh"
        do [[ -r "$_f" ]] && { source "$_f"; break; }; done
        for _f in \
            /usr/share/fzf/completion.zsh \
            /usr/share/doc/fzf/examples/completion.zsh \
            "$HOME/.fzf/shell/completion.zsh"
        do [[ -r "$_f" ]] && { source "$_f"; break; }; done
    fi
    unset _f
fi

# zsh-autosuggestions — load from the package-manager path or scoop install.
for _f in \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    "$HOME/scoop/apps/zsh-autosuggestions/current/zsh-autosuggestions.zsh"
do [[ -r "$_f" ]] && { source "$_f"; break; }; done

# zsh-syntax-highlighting — MUST be the very last thing sourced.
for _f in \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    "$HOME/scoop/apps/zsh-syntax-highlighting/current/zsh-syntax-highlighting.zsh"
do [[ -r "$_f" ]] && { source "$_f"; break; }; done
unset _f
