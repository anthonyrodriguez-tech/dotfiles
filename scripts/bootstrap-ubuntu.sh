#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Ubuntu / Debian bootstrap — apt + upstream installers + chezmoi.
# WHERE : scripts/bootstrap-ubuntu.sh
# WHY   : apt repos are missing or carry stale versions of several tools
#         in our stack (chezmoi, starship, atuin, mise, eza, lazygit,
#         git-delta). For each, we fall back to the official upstream
#         installer that drops a binary into ~/.local/bin.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-ubuntu.sh | bash
#   ./scripts/bootstrap-ubuntu.sh
#
# Sudo is only used for `apt-get` and the optional /etc/shells edit.
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

if [ "$(uname -s)" != "Linux" ] || ! has_cmd apt-get; then
    log::err "this script is Ubuntu/Debian-only — apt-get not found"
    exit 1
fi

SUDO=""
if [ "$(id -u)" -ne 0 ] && has_cmd sudo; then
    SUDO="sudo"
fi

# ── apt: only what's reliably packaged ────────────────────────────────────
log::step "apt-get update + install"
${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends \
    zsh git curl ca-certificates build-essential unzip \
    ripgrep fd-find bat neovim tmux jq \
    fzf zoxide \
    xclip wl-clipboard

# Debian names `fd` binary `fdfind` and `bat` `batcat` — symlink into ~/.local/bin.
mkdir -p "${HOME}/.local/bin"
if ! has_cmd fd && has_cmd fdfind; then
    ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
fi
if ! has_cmd bat && has_cmd batcat; then
    ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
fi

export PATH="${HOME}/.local/bin:${PATH}"

# ── Upstream installers (apt versions are too old or missing) ─────────────

# chezmoi — official one-liner lands a binary in ~/.local/bin if non-root.
if ! has_cmd chezmoi; then
    log::step "chezmoi (upstream installer)"
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin"
fi

# starship — apt does not ship it on most LTS releases.
if ! has_cmd starship; then
    log::step "starship (upstream installer)"
    curl -fsSL https://starship.rs/install.sh |
        sh -s -- --yes --bin-dir "${HOME}/.local/bin"
fi

# mise — single-binary installer, works on any Ubuntu version.
if ! has_cmd mise; then
    log::step "mise (upstream installer)"
    curl -fsSL https://mise.run | sh
fi

# atuin — upstream installer.
if ! has_cmd atuin; then
    log::step "atuin (upstream installer)"
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh -s -- --no-modify-path
fi

# eza — installed from the latest GitHub release tarball.
if ! has_cmd eza; then
    log::step "eza (GitHub release)"
    EZA_VERSION="$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest | jq -r .tag_name)"
    curl -fsSL -o /tmp/eza.tar.gz \
        "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
    tar -xzf /tmp/eza.tar.gz -C "${HOME}/.local/bin" eza
    rm -f /tmp/eza.tar.gz
fi

# lazygit — GitHub release.
if ! has_cmd lazygit; then
    log::step "lazygit (GitHub release)"
    LG_VERSION="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name | sed 's/v//')"
    curl -fsSL -o /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
    tar -xzf /tmp/lazygit.tar.gz -C "${HOME}/.local/bin" lazygit
    rm -f /tmp/lazygit.tar.gz
fi

# git-delta — GitHub release (.deb, needs sudo).
if ! has_cmd delta; then
    if [ -n "${SUDO}" ]; then
        log::step "git-delta (.deb release)"
        DELTA_VERSION="$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest | jq -r .tag_name)"
        curl -fsSL -o /tmp/delta.deb \
            "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
        ${SUDO} dpkg -i /tmp/delta.deb
        rm -f /tmp/delta.deb
    else
        log::warn "delta missing and no sudo — diffs will fall back to git default pager"
    fi
fi

# gh (GitHub CLI) — apt repo is a multi-step install, use the upstream script.
if ! has_cmd gh; then
    if [ -n "${SUDO}" ]; then
        log::step "gh (apt repo via upstream script)"
        ${SUDO} mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
            ${SUDO} tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        ${SUDO} chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
            ${SUDO} tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        ${SUDO} apt-get update
        ${SUDO} apt-get install -y gh
    else
        log::warn "gh missing and no sudo — install manually if you need GitHub CLI"
    fi
fi

# JetBrains Mono Nerd Font — drop into ~/.local/share/fonts.
NERD_FONT_DIR="${HOME}/.local/share/fonts/JetBrainsMono"
if [ ! -d "${NERD_FONT_DIR}" ]; then
    log::step "JetBrainsMono Nerd Font (GitHub release)"
    mkdir -p "${NERD_FONT_DIR}"
    curl -fsSL -o /tmp/jbmono.zip \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -qo /tmp/jbmono.zip -d "${NERD_FONT_DIR}"
    rm -f /tmp/jbmono.zip
    fc-cache -f "${NERD_FONT_DIR}" >/dev/null 2>&1 || true
fi

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
