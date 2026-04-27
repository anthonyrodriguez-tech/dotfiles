#!/usr/bin/env bash
# uninstall.sh — undo install.sh on Linux (Arch or Ubuntu).
# Removes chezmoi state + claude/omp binaries. Keeps system packages
# (they're shared with the rest of your system).

set -u

step() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [ "${1:-}" != "--force" ] && [ "${1:-}" != "-f" ]; then
    printf 'Remove chezmoi state, claude, and omp from $HOME? (y/N): '
    read -r reply
    case "$reply" in
        y|Y) ;;
        *) ok 'aborted'; exit 0 ;;
    esac
fi

step "chezmoi purge"
if have chezmoi; then
    chezmoi purge --force 2>/dev/null || true
fi
rm -rf "${HOME}/.local/share/chezmoi" "${HOME}/.config/chezmoi" "${HOME}/.cache/chezmoi"

step "claude + omp"
rm -f "${HOME}/.local/bin/claude" "${HOME}/.local/bin/omp"
[ -d "${HOME}/.claude" ] && printf '  ! kept ~/.claude — delete manually if desired\n'
[ -d "${HOME}/.omp" ]    && printf '  ! kept ~/.omp — delete manually if desired\n'

step "done"
ok "system packages preserved — remove with pacman -Rns / apt remove if needed"
