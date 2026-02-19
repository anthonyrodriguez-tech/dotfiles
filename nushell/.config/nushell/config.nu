# config.nu

$env.config = {
    show_banner: false

    history: {
        max_size: 10000
        sync_on_enter: true
        file_format: "plaintext"
        isolation: false
    }

    cursor_shape: {
        emacs: block
        vi_insert: block
        vi_normal: underscore
    }

    edit_mode: emacs

    table: {
        mode: rounded
        index_mode: always
    }
}

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ll  = ls -l
alias la  = ls -la
alias ..  = cd ..
alias ... = cd ../..

# ── Zoxide ────────────────────────────────────────────────────────────────────
source ~/.config/nushell/zoxide.nu

# ── Starship ──────────────────────────────────────────────────────────────────
source ~/.cache/starship/init.nu
