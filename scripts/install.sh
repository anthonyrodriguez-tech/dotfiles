#!/usr/bin/env bash
# Linux entry point — Ubuntu/Debian or Arch (incl. WSL2). One file, no TUI.
#
#   curl -fsSL https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.sh | bash
#   ./scripts/install.sh

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/tony/dotfiles.git}"
BRANCH="${DOTFILES_BRANCH:-main}"
SOURCE_DIR="${HOME}/.local/share/chezmoi"

step() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
ok() { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*" >&2; }
err() {
    printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2
    exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(uname -s)" = "Linux" ] || err "Linux only — use scripts/install.ps1 on Windows."

SUDO=""
[ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"

# ── 1. Detect distro ──────────────────────────────────────────────────────
if have pacman; then
    DISTRO=arch
elif have apt-get; then
    DISTRO=ubuntu
else
    err "unsupported Linux: need pacman or apt-get"
fi
ok "distro: ${DISTRO}"

# ── 2. Proxy / identity prompts (skipped if already set in env) ───────────
read_default() {
    local label="$1" def="${2:-}" resp=""
    if [ -n "$def" ]; then printf '%s [%s]: ' "$label" "$def" >&2
    else printf '%s: ' "$label" >&2; fi
    IFS= read -r resp || true
    [ -z "$resp" ] && resp="$def"
    printf '%s\n' "$resp"
}

PROXY_HTTP="${HTTP_PROXY:-${http_proxy:-}}"
PROXY_HTTPS="${HTTPS_PROXY:-${https_proxy:-}}"
if [ -z "$PROXY_HTTP" ] && [ -z "$PROXY_HTTPS" ]; then
    PROXY_HTTP="$(read_default 'HTTP proxy URL (blank if none)' '')"
    PROXY_HTTPS="$(read_default 'HTTPS proxy URL (blank if none)' "$PROXY_HTTP")"
fi
if [ -n "$PROXY_HTTP" ]; then
    export HTTP_PROXY="$PROXY_HTTP" http_proxy="$PROXY_HTTP"
fi
if [ -n "$PROXY_HTTPS" ]; then
    export HTTPS_PROXY="$PROXY_HTTPS" https_proxy="$PROXY_HTTPS"
fi

NAME="$(read_default 'Full name' "${USER:-user}")"
EMAIL="$(read_default 'Email address' "${USER:-user}@localhost")"

# ── 3. Prerequisites ──────────────────────────────────────────────────────
step "installing prerequisites"
case "$DISTRO" in
arch)
    ${SUDO} pacman -Sy --needed --noconfirm git curl zsh chezmoi
    ;;
ubuntu)
    ${SUDO} apt-get update
    ${SUDO} apt-get install -y --no-install-recommends git curl ca-certificates zsh
    if ! have chezmoi; then
        sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "${HOME}/.local/bin"
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
    ;;
esac

# ── 4. Clone source dir if running via curl-pipe ──────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/install.sh" ]; then
    if [ ! -d "${SOURCE_DIR}/.git" ]; then
        step "cloning ${REPO_URL} → ${SOURCE_DIR}"
        mkdir -p "$(dirname "${SOURCE_DIR}")"
        git clone --depth=1 --branch "${BRANCH}" "${REPO_URL}" "${SOURCE_DIR}"
    fi
fi

# ── 5. Pre-write chezmoi.toml so init does not prompt ─────────────────────
mkdir -p "${HOME}/.config/chezmoi"
cat > "${HOME}/.config/chezmoi/chezmoi.toml" <<EOF
[data]
    name        = "${NAME}"
    email       = "${EMAIL}"
    proxy_http  = "${PROXY_HTTP}"
    proxy_https = "${PROXY_HTTPS}"
EOF

# ── 6. chezmoi init --apply ───────────────────────────────────────────────
step "chezmoi init --apply ${REPO_URL}"
chezmoi init --apply "${REPO_URL}"

# ── 7. Default shell → zsh ────────────────────────────────────────────────
ZSH_PATH="$(command -v zsh || true)"
if [ -n "$ZSH_PATH" ] && [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    [ -n "$SUDO" ] && ! grep -q "^${ZSH_PATH}$" /etc/shells \
        && echo "$ZSH_PATH" | ${SUDO} tee -a /etc/shells >/dev/null
    chsh -s "$ZSH_PATH" || warn "chsh failed — set default shell manually"
fi

step "done"
ok "open a new terminal — zsh + starship should greet you"
ok "claude  (first launch prompts for browser login)"
ok "omp     (configure providers via /login)"
