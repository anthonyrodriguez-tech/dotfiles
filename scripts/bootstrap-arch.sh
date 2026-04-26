#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Arch Linux bootstrap — pacman + upstream installers + chezmoi.
# WHERE : scripts/bootstrap-arch.sh
# WHY   : pacman ships almost everything we need, including chezmoi /
#         lazygit / git-delta / starship / atuin / mise / eza, so this
#         script is shorter than the Ubuntu one. omp + claude come from
#         their official upstream installers.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-arch.sh | bash
#   ./scripts/bootstrap-arch.sh
#
# Sudo is only used for `pacman -Sy` and the optional /etc/shells edit.
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
if [ -n "${SCRIPT_DIR}" ] && [ -f "${SCRIPT_DIR}/common/lib.sh" ]; then
    # shellcheck source=scripts/common/lib.sh
    . "${SCRIPT_DIR}/common/lib.sh"
else
    _LIB_URL="https://raw.githubusercontent.com/tony/dotfiles/main/scripts/common/lib.sh"
    _LIB_TMP="$(mktemp)"
    curl -fsSL "${_LIB_URL}" -o "${_LIB_TMP}"
    # shellcheck disable=SC1090
    . "${_LIB_TMP}"
    rm -f "${_LIB_TMP}"
fi

REPO_URL="${DOTFILES_REPO:-https://github.com/tony/dotfiles.git}"

if [ "$(uname -s)" != "Linux" ] || ! has_cmd pacman; then
    log::err "this script is Arch-only — got $(uname -s), pacman missing: $(! has_cmd pacman && echo yes || echo no)"
    exit 1
fi

SUDO=""
if [ "$(id -u)" -ne 0 ] && has_cmd sudo; then
    SUDO="sudo"
fi

# ── Packages (pacman covers everything except claude / omp) ───────────────
log::step "pacman -Sy"
${SUDO} pacman -Sy --needed --noconfirm \
    zsh git curl base-devel unzip \
    ripgrep fd bat neovim tmux jq yq \
    fzf zoxide eza starship atuin mise \
    chezmoi lazygit git-delta github-cli ttf-jetbrains-mono-nerd \
    xclip wl-clipboard

# ── Default shell ─────────────────────────────────────────────────────────
log::step "Default shell"
ZSH_PATH="$(command -v zsh || true)"
if [ -n "${ZSH_PATH}" ] && [ "${SHELL:-}" != "${ZSH_PATH}" ]; then
    if [ -n "${SUDO}" ] && ! grep -q "^${ZSH_PATH}$" /etc/shells; then
        echo "${ZSH_PATH}" | ${SUDO} tee -a /etc/shells >/dev/null
    fi
    chsh -s "${ZSH_PATH}" || log::warn "chsh failed — set default shell manually"
else
    log::ok "already zsh or zsh missing"
fi

# ── Claude Code (native installer) ────────────────────────────────────────
if ! has_cmd claude; then
    log::step "Claude Code (native installer)"
    curl -fsSL https://claude.ai/install.sh | bash
else
    log::ok "claude already installed"
fi

# ── oh-my-pi (omp) — AI coding agent (fork of pi-mono) ────────────────────
if ! has_cmd omp; then
    log::step "oh-my-pi (upstream installer)"
    curl -fsSL https://raw.githubusercontent.com/can1357/oh-my-pi/main/scripts/install.sh | sh
else
    log::ok "omp already installed"
fi

# ── Interactive TUI (gum) → writes ~/.config/chezmoi/chezmoi.toml ─────────
# tui::run also calls chezmoi_bootstrap once the user has confirmed.
log::step "interactive setup"
if [ -n "${SCRIPT_DIR:-}" ] && [ -f "${SCRIPT_DIR}/common/tui.sh" ]; then
    # shellcheck source=scripts/common/tui.sh
    . "${SCRIPT_DIR}/common/tui.sh"
else
    log::err "tui.sh not found — run scripts/install.sh from a local clone."
    exit 1
fi
DOTFILES_REPO="${REPO_URL}" tui::run

log::step "done"
log::ok "open a new terminal — zsh + starship should greet you"
log::ok "then run: claude  (first launch prompts for browser login)"
log::ok "and:     omp     (configure providers via /login)"
