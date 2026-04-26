#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Arch uninstall — reverses bootstrap-arch.sh in safe mode.
# WHERE : scripts/uninstall-arch.sh
# WHY   : Clean recovery from a broken bootstrap, or removal of the
#         user-level pieces (chezmoi state, claude/omp binaries) without
#         touching system packages — pacman packages are shared with the
#         rest of the system and removing them is the user's call.
#
# Usage:
#   ./scripts/uninstall-arch.sh           # asks for confirmation
#   ./scripts/uninstall-arch.sh -y        # skip confirmation
#
# What it does:
#   1. chezmoi purge (source repo + chezmoi config + cache)
#   2. Remove user-installed binaries from ~/.local/bin
#      (claude, omp, plus any upstream-installed starship/atuin/mise/chezmoi)
#   3. Reset login shell to /bin/bash
#
# What it does NOT do:
#   - Remove pacman packages — they may be used by other software.
#     If you want them gone: `pacman -Rns zsh git neovim ...` manually.
#   - Delete files already deployed to $HOME (e.g. ~/.zshrc) — chezmoi
#     purge only clears its own state. Remove deployed files by hand.
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
if [ -n "${SCRIPT_DIR}" ] && [ -f "${SCRIPT_DIR}/common/lib.sh" ]; then
    # shellcheck source=scripts/common/lib.sh
    . "${SCRIPT_DIR}/common/lib.sh"
else
    echo "uninstall-arch.sh must be run from the dotfiles repo (lib.sh missing)" >&2
    exit 1
fi

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help)
        sed -n '2,/^# ──*$/p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        log::err "unknown flag: $arg (try --help)"
        exit 2
        ;;
    esac
done

if [ "${ASSUME_YES}" -ne 1 ]; then
    log::warn "This will purge chezmoi state and remove ~/.local/bin/{claude,omp,starship,atuin,mise,chezmoi} if present."
    log::warn "pacman packages (zsh, git, neovim, ...) will NOT be removed."
    printf "Continue? (y/N) "
    read -r reply
    case "$reply" in
    y | Y | yes | YES) ;;
    *)
        log::ok "aborted"
        exit 0
        ;;
    esac
fi

# ── 1. chezmoi purge ──────────────────────────────────────────────────────
log::step "chezmoi purge"
if has_cmd chezmoi; then
    chezmoi purge --force || log::warn "chezmoi purge returned non-zero"
else
    for d in "${HOME}/.local/share/chezmoi" "${HOME}/.config/chezmoi" "${HOME}/.cache/chezmoi"; do
        if [ -d "$d" ]; then
            rm -rf "$d"
            log::ok "removed $d"
        fi
    done
fi

# ── 2. User-installed binaries ────────────────────────────────────────────
log::step "User binaries in ~/.local/bin"
USER_BINS=(claude omp starship atuin mise chezmoi)
for bin in "${USER_BINS[@]}"; do
    p="${HOME}/.local/bin/${bin}"
    if [ -e "$p" ] || [ -L "$p" ]; then
        rm -f "$p"
        log::ok "removed $p"
    fi
done

# omp + claude data dirs (settings, sessions, credentials).
for d in "${HOME}/.omp" "${HOME}/.claude" "${HOME}/.claude.json"; do
    if [ -e "$d" ]; then
        log::warn "kept $d (contains your settings/history/credentials) — delete manually if desired"
    fi
done

# ── 3. Default shell ──────────────────────────────────────────────────────
log::step "Default shell → /bin/bash"
if [ -x /bin/bash ] && [ "${SHELL:-}" != "/bin/bash" ]; then
    chsh -s /bin/bash || log::warn "chsh failed — set default shell manually"
else
    log::ok "already bash or bash missing"
fi

log::step "done"
log::ok "open a new terminal to land in bash"
log::warn "pacman packages preserved — run 'pacman -Rns ...' manually if you want a full wipe"
