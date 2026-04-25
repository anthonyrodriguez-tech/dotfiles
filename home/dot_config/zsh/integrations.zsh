# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : init hooks for tools that wrap the prompt or key bindings.
# WHERE : home/dot_config/zsh/integrations.zsh  →  ~/.config/zsh/integrations.zsh
# WHY   : Sourced LAST so that:
#           • starship gets the final $PROMPT slot (overrides any earlier prompt)
#           • zoxide / atuin can hook chpwd / preexec after our other hooks
#           • fzf binds Ctrl-R / Ctrl-T / Alt-C after keybinds.zsh ran, so
#             fzf wins the conflict (intended).
# ─────────────────────────────────────────────────────────────────────────────

# ── Starship prompt ───────────────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ── zoxide (smarter cd; --cmd cd shadows the builtin) ─────────────────────
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# ── fzf key bindings + completion ─────────────────────────────────────────
# fzf ≥ 0.48 ships `fzf --zsh` which prints both. On older versions we
# fall back to sourcing the per-distro install paths.
if command -v fzf >/dev/null 2>&1; then
    local _fzf_init
    if _fzf_init="$(fzf --zsh 2>/dev/null)" && [[ -n "$_fzf_init" ]]; then
        eval "$_fzf_init"
    else
        for _f in \
            /usr/share/fzf/key-bindings.zsh \
            /usr/share/doc/fzf/examples/key-bindings.zsh \
            "$HOME/.fzf/shell/key-bindings.zsh"
        do
            [[ -r "$_f" ]] && { source "$_f"; break; }
        done
        for _f in \
            /usr/share/fzf/completion.zsh \
            /usr/share/doc/fzf/examples/completion.zsh \
            "$HOME/.fzf/shell/completion.zsh"
        do
            [[ -r "$_f" ]] && { source "$_f"; break; }
        done
        unset _f
    fi
    unset _fzf_init
fi

# ── direnv (per-dir env via .envrc) ───────────────────────────────────────
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# ── atuin (better history search) — keep up-arrow on prefix-search ────────
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi
