#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : single entry point for the dotfiles framework on Linux.
#         Clones the repo into ~/.local/share/chezmoi if not already
#         there, then exec's the right bootstrap-<distro>.sh.
# WHERE : scripts/install.sh
# WHY   : having ONE curl-pipe-friendly URL is the "Plug & Play" promise.
#         The user doesn't have to know whether they're on Arch or Ubuntu.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.sh | bash
#   ./scripts/install.sh
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/tony/dotfiles.git}"
BRANCH="${DOTFILES_BRANCH:-main}"
SOURCE_DIR="${HOME}/.local/share/chezmoi"

step() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
err() {
    printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2
    exit 1
}

# ── 1. Sanity ─────────────────────────────────────────────────────────────
case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux) ;;
    MINGW* | MSYS* | CYGWIN*)
        err "Detected Windows shell — run scripts/install.ps1 from PowerShell instead."
        ;;
    Darwin)
        err "macOS is not (yet) supported. Open an issue if you need it."
        ;;
    *)
        err "Unsupported OS: $(uname -s)"
        ;;
esac

# ── 2. Resolve script dir (local checkout vs curl-pipe) ───────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

# When running via `curl | bash`, BASH_SOURCE is /dev/stdin and SCRIPT_DIR
# is empty. Clone the repo to its canonical location.
if [ -z "${SCRIPT_DIR}" ] || [ ! -f "${SCRIPT_DIR}/common/lib.sh" ]; then
    if [ ! -d "${SOURCE_DIR}/.git" ]; then
        step "cloning ${REPO_URL} → ${SOURCE_DIR}"
        if ! command -v git >/dev/null 2>&1; then
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --needed --noconfirm git
            elif command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y git
            else
                err "git not found — install git manually and re-run."
            fi
        fi
        mkdir -p "$(dirname "${SOURCE_DIR}")"
        git clone --depth=1 --branch "${BRANCH}" "${REPO_URL}" "${SOURCE_DIR}"
    else
        step "repo already at ${SOURCE_DIR} — pulling latest"
        git -C "${SOURCE_DIR}" pull --ff-only --quiet || true
    fi
    SCRIPT_DIR="${SOURCE_DIR}/scripts"
fi

# ── 3. Distro dispatch ────────────────────────────────────────────────────
if command -v pacman >/dev/null 2>&1; then
    exec "${SCRIPT_DIR}/bootstrap-arch.sh"
elif command -v apt-get >/dev/null 2>&1; then
    exec "${SCRIPT_DIR}/bootstrap-ubuntu.sh"
else
    err "Linux distro without pacman or apt-get is unsupported."
fi
