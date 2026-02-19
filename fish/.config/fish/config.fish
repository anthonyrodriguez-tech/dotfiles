if status is-interactive

    # ── Path ──────────────────────────────────────────────────────────────────
    fish_add_path ~/.local/bin

    # ── Zoxide ────────────────────────────────────────────────────────────────
    zoxide init fish | source

    # ── Aliases ───────────────────────────────────────────────────────────────
    alias ls  'ls --color=auto'
    alias ll  'ls -lh --color=auto'
    alias la  'ls -lah --color=auto'
    alias ..  'cd ..'
    alias ... 'cd ../..'

    # ── Greeting ──────────────────────────────────────────────────────────────
    set fish_greeting ""

end
