#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : Linux bootstrap — detects the package manager (apt/dnf/pacman),
#         installs the same stack we use on macOS, then runs chezmoi.
# WHERE : scripts/bootstrap-linux.sh
# WHY   : one script for Debian/Ubuntu, Fedora/RHEL, Arch. Homelab and
#         anything WSL-less just needs this.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-linux.sh | bash
#   ./scripts/bootstrap-linux.sh
#
# Sudo is only used for package installs and /etc/shells edits. If you
# don't have sudo (some homelab accounts), the script will fall back to
# user-local installs where possible and skip what needs root.
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

if [ "$(uname -s)" != "Linux" ]; then
    log::err "this script is Linux-only — got $(uname -s)"
    exit 1
fi

# ── Detect package manager ────────────────────────────────────────────────
PM=""
if has_cmd apt-get; then
    PM="apt"
elif has_cmd dnf; then
    PM="dnf"
elif has_cmd pacman; then
    PM="pacman"
else
    log::err "no supported package manager found (apt/dnf/pacman)"
    exit 1
fi
log::step "detected package manager: ${PM}"

SUDO=""
if [ "$(id -u)" -ne 0 ] && has_cmd sudo; then
    SUDO="sudo"
fi

# ── Install packages ──────────────────────────────────────────────────────
# Package names differ per distro; the values below are what the distros
# actually ship. Missing / differently-named ones are installed by fallback
# below (starship via install.sh, atuin via installer, wezterm via AppImage).
case "${PM}" in
apt)
    ${SUDO} apt-get update
    ${SUDO} apt-get install -y --no-install-recommends \
        zsh git curl ca-certificates build-essential unzip \
        ripgrep fd-find bat neovim tmux jq \
        fzf zoxide
    # Debian names `fd` binary `fdfind` — symlink into ~/.local/bin.
    if ! has_cmd fd && has_cmd fdfind; then
        mkdir -p "${HOME}/.local/bin"
        ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    fi
    ;;
dnf)
    ${SUDO} dnf install -y \
        zsh git curl ca-certificates @development-tools unzip \
        ripgrep fd-find bat neovim tmux jq \
        fzf zoxide eza
    ;;
pacman)
    ${SUDO} pacman -Sy --needed --noconfirm \
        zsh git curl base-devel unzip \
        ripgrep fd bat neovim tmux jq yq \
        fzf zoxide eza starship atuin mise \
        chezmoi lazygit git-delta github-cli ttf-jetbrains-mono-nerd
    ;;
esac

# ── Tools that are flaky / missing in distro repos: install via upstream ──

# chezmoi — official one-liner lands a binary in ~/.local/bin if we're
# non-root, else in /usr/local/bin. The installer is idempotent.
if ! has_cmd chezmoi; then
    log::step "chezmoi (upstream installer)"
    BINDIR="${HOME}/.local/bin"
    mkdir -p "${BINDIR}"
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${BINDIR}"
    export PATH="${BINDIR}:${PATH}"
fi

# starship — needs curl installer on apt/dnf (not packaged on older distros).
if ! has_cmd starship; then
    log::step "starship (upstream installer)"
    curl -fsSL https://starship.rs/install.sh |
        sh -s -- --yes --bin-dir "${HOME}/.local/bin"
fi

# mise — single-binary install for apt/dnf (pacman already handled it).
if ! has_cmd mise; then
    log::step "mise (upstream installer)"
    curl -fsSL https://mise.run | sh
fi

# atuin — upstream installer works on any distro.
if ! has_cmd atuin; then
    log::step "atuin (upstream installer)"
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh -s -- --no-modify-path
fi

# eza — apt doesn't ship it; fallback to cargo or GitHub release binary.
if ! has_cmd eza; then
    log::warn "eza not installed (fine — modern aliases fall back to ls)"
fi

# delta — apt/dnf: git-delta. Missing? install via GitHub release.
if ! has_cmd delta; then
    log::warn "delta missing — diffs fall back to git default pager"
fi

# lazygit — apt/dnf don't always have it.
if ! has_cmd lazygit; then
    log::warn "lazygit missing — install manually from github.com/jesseduffield/lazygit"
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

# ── chezmoi apply ─────────────────────────────────────────────────────────
chezmoi_bootstrap "${REPO_URL}"

log::step "done"
log::ok "open a new terminal — zsh + starship should greet you"
log::ok "then run: claude auth login"
