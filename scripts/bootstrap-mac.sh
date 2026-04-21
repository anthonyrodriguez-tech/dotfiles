#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : macOS bootstrap — installs Homebrew + deps, then chezmoi init.
# WHERE : scripts/bootstrap-mac.sh
# WHY   : single idempotent entry point. Fresh Mac → working environment
#         in ~15 min depending on bandwidth.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-mac.sh | bash
# Or clone and run:
#   ./scripts/bootstrap-mac.sh
#
# Safe to re-run; nothing is reinstalled if already present.
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Locate lib.sh whether we're piped via curl or run from the repo.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
if [ -n "${SCRIPT_DIR}" ] && [ -f "${SCRIPT_DIR}/common/lib.sh" ]; then
    # shellcheck source=scripts/common/lib.sh
    . "${SCRIPT_DIR}/common/lib.sh"
else
    # Piped-from-curl path: fetch lib.sh too.
    _LIB_URL="https://raw.githubusercontent.com/tony/dotfiles/main/scripts/common/lib.sh"
    _LIB_TMP="$(mktemp)"
    curl -fsSL "${_LIB_URL}" -o "${_LIB_TMP}"
    # shellcheck disable=SC1090
    . "${_LIB_TMP}"
    rm -f "${_LIB_TMP}"
fi

REPO_URL="${DOTFILES_REPO:-https://github.com/tony/dotfiles.git}"

# ── sanity ────────────────────────────────────────────────────────────────
if [ "$(uname -s)" != "Darwin" ]; then
    log::err "this script is macOS-only — got $(uname -s)"
    exit 1
fi

# ── 1. Xcode Command Line Tools ───────────────────────────────────────────
log::step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
    log::ok "already installed"
else
    xcode-select --install || true
    log::warn "Xcode CLT installer opened — re-run this script once it finishes"
    exit 0
fi

# ── 2. Homebrew ───────────────────────────────────────────────────────────
log::step "Homebrew"
if has_cmd brew; then
    log::ok "already installed"
else
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for the remainder of this script (Apple Silicon vs Intel).
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ── 3. Packages ───────────────────────────────────────────────────────────
# Formulas — CLI tools that match what the zsh/nvim config expects.
BREW_FORMULAS=(
    zsh chezmoi neovim lazygit git git-delta gh
    starship zoxide fzf ripgrep fd bat eza atuin mise
    tmux jq yq tree
)

# Casks — GUI apps + fonts.
BREW_CASKS=(
    wezterm
    font-jetbrains-mono-nerd-font
)

log::step "Homebrew formulas"
for pkg in "${BREW_FORMULAS[@]}"; do
    if brew list --formula "${pkg}" >/dev/null 2>&1; then
        log::ok "${pkg}"
    else
        brew install "${pkg}"
    fi
done

log::step "Homebrew casks"
for pkg in "${BREW_CASKS[@]}"; do
    if brew list --cask "${pkg}" >/dev/null 2>&1; then
        log::ok "${pkg}"
    else
        brew install --cask "${pkg}"
    fi
done

# ── 4. Default shell → zsh ────────────────────────────────────────────────
log::step "Default shell"
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ "${SHELL:-}" = "${BREW_ZSH}" ]; then
    log::ok "already zsh (brew)"
elif [ -x "${BREW_ZSH}" ]; then
    if ! grep -q "${BREW_ZSH}" /etc/shells; then
        log::step "registering ${BREW_ZSH} in /etc/shells (sudo)"
        echo "${BREW_ZSH}" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "${BREW_ZSH}" || log::warn "chsh failed — set default shell manually"
fi

# ── 5. Claude Code (native installer, replaces legacy `npm i -g`) ────────
if ! has_cmd claude; then
    log::step "Claude Code (native installer)"
    curl -fsSL https://claude.ai/install.sh | bash
else
    log::ok "claude already installed"
fi

# ── 6. chezmoi ────────────────────────────────────────────────────────────
chezmoi_bootstrap "${REPO_URL}"

log::step "done"
log::ok "open a new wezterm window — zsh + starship should greet you"
log::ok "then run: claude  (first launch prompts for browser login)"
