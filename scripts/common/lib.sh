#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : shared bash helpers — log, install-if-missing, chezmoi bootstrap.
# WHERE : scripts/common/lib.sh, sourced by bootstrap-{arch,ubuntu}.sh
#         and uninstall-{arch,ubuntu}.sh.
# WHY   : idempotence + clean logs + a single place for the chezmoi init
#         invocation so the per-distro scripts don't drift apart.
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Colour helpers (disabled when stdout is not a TTY, e.g. piped to tee).
if [ -t 1 ]; then
    readonly _C_RESET=$'\033[0m'
    readonly _C_BOLD=$'\033[1m'
    readonly _C_BLUE=$'\033[34m'
    readonly _C_GREEN=$'\033[32m'
    readonly _C_YELLOW=$'\033[33m'
    readonly _C_RED=$'\033[31m'
else
    readonly _C_RESET=""
    readonly _C_BOLD=""
    readonly _C_BLUE=""
    readonly _C_GREEN=""
    readonly _C_YELLOW=""
    readonly _C_RED=""
fi

log::step() { printf '%s==> %s%s\n' "${_C_BOLD}${_C_BLUE}" "$*" "${_C_RESET}"; }
log::ok() { printf '%s  ✓ %s%s\n' "${_C_GREEN}" "$*" "${_C_RESET}"; }
log::warn() { printf '%s  ! %s%s\n' "${_C_YELLOW}" "$*" "${_C_RESET}" >&2; }
log::err() { printf '%s  ✗ %s%s\n' "${_C_RED}${_C_BOLD}" "$*" "${_C_RESET}" >&2; }

# has_cmd <name> — 0 if in PATH, 1 otherwise.
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# require <name> <hint> — fail fast if a prerequisite is missing.
require() {
    if ! has_cmd "$1"; then
        log::err "missing prerequisite: $1"
        [ -n "${2:-}" ] && log::err "hint: $2"
        exit 1
    fi
}

# chezmoi_bootstrap <repo-url> — init + apply, idempotent.
# If chezmoi is already initialised on this machine, run `apply` only.
chezmoi_bootstrap() {
    local repo="$1"
    require chezmoi "install chezmoi via pacman / apt / scoop first"

    if [ -d "${HOME}/.local/share/chezmoi" ] ||
        [ -d "${HOME}/.config/chezmoi" ]; then
        log::step "chezmoi already initialised — running apply"
        chezmoi apply --verbose
    else
        log::step "chezmoi init --apply from ${repo}"
        chezmoi init --apply "${repo}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────
# OS detection + package-manager dispatch
#
# os::detect       echoes one of: arch ubuntu windows unknown
# pkg::installed_p <bin>            — 0 if the binary exists, 1 otherwise
# pkg::install_many <pkg1> [<pkg2>] — install N packages via detected PM,
#                                     idempotent (PM-side --needed / -y).
# ─────────────────────────────────────────────────────────────────────────

os::detect() {
    case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux)
        if has_cmd pacman; then
            echo arch
        elif has_cmd apt-get; then
            echo ubuntu
        else
            echo unknown
        fi
        ;;
    MINGW* | MSYS* | CYGWIN*)
        echo windows
        ;;
    *)
        echo unknown
        ;;
    esac
}

pkg::installed_p() { has_cmd "$1"; }

pkg::install_many() {
    [ "$#" -gt 0 ] || return 0
    if [ "${DOTFILES_DRY_RUN:-0}" = "1" ]; then
        log::ok "DRY_RUN: would install: $*"
        return 0
    fi
    local os
    os="$(os::detect)"
    local SUDO=""
    if [ "$(id -u 2>/dev/null || echo 0)" -ne 0 ] && has_cmd sudo; then
        SUDO="sudo"
    fi
    case "$os" in
    arch)
        ${SUDO} pacman -S --needed --noconfirm "$@"
        ;;
    ubuntu)
        ${SUDO} apt-get install -y --no-install-recommends "$@"
        ;;
    windows)
        require scoop "scoop must be in PATH (bootstrap-windows.ps1 sets it up)"
        local p
        for p in "$@"; do
            scoop install "$p"
        done
        ;;
    *)
        log::err "pkg::install_many: unsupported OS '${os}'"
        return 1
        ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────
# POSIX prompt fallbacks (used when gum is unavailable, e.g. proxy strict
# corporate machines where the gum binary cannot be downloaded).
#
# All prompts WRITE the question to stderr and ECHO the answer to stdout,
# so callers do `value="$(prompt::input "Email")"` regardless of TTY.
# ─────────────────────────────────────────────────────────────────────────

prompt::input() {
    local label="$1" def="${2:-}" resp=""
    if [ -n "$def" ]; then
        printf '%s [%s]: ' "$label" "$def" >&2
    else
        printf '%s: ' "$label" >&2
    fi
    IFS= read -r resp || true
    [ -z "$resp" ] && resp="$def"
    printf '%s\n' "$resp"
}

prompt::choose() {
    local label="$1"
    shift
    local opts=("$@") i resp=""
    printf '%s\n' "$label" >&2
    for i in "${!opts[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${opts[$i]}" >&2
    done
    while :; do
        printf 'Choice (number): ' >&2
        IFS= read -r resp || true
        if printf '%s' "$resp" | grep -qE '^[0-9]+$' &&
            [ "$resp" -ge 1 ] && [ "$resp" -le "${#opts[@]}" ]; then
            printf '%s\n' "${opts[$((resp - 1))]}"
            return 0
        fi
    done
}

prompt::multi_choose() {
    local label="$1"
    shift
    local opts=("$@") picked=() resp="" n
    printf '%s\n' "$label" >&2
    for i in "${!opts[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${opts[$i]}" >&2
    done
    printf 'Numbers separated by space (empty = none): ' >&2
    IFS= read -r resp || true
    for n in $resp; do
        if printf '%s' "$n" | grep -qE '^[0-9]+$' &&
            [ "$n" -ge 1 ] && [ "$n" -le "${#opts[@]}" ]; then
            picked+=("${opts[$((n - 1))]}")
        fi
    done
    if [ "${#picked[@]}" -gt 0 ]; then
        printf '%s\n' "${picked[@]}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────
# gum::ensure — make `gum` available, return 1 if we cannot.
# Tries the OS PM first, then falls back to the official upstream tarball
# for Ubuntu (apt only ships gum from 24.04 onwards).
# ─────────────────────────────────────────────────────────────────────────

readonly _GUM_VERSION="0.14.5"

gum::ensure() {
    if has_cmd gum; then return 0; fi
    log::step "installing gum"
    local os
    os="$(os::detect)"
    case "$os" in
    arch)
        pkg::install_many gum && return 0
        ;;
    ubuntu)
        pkg::install_many gum 2>/dev/null && return 0
        log::warn "apt has no 'gum' package — falling back to upstream binary"
        gum::_install_from_upstream && return 0
        ;;
    windows)
        scoop install charm-gum 2>/dev/null && return 0
        scoop install gum 2>/dev/null && return 0
        ;;
    esac
    log::warn "gum unavailable — TUI will fall back to plain text prompts"
    return 1
}

gum::_install_from_upstream() {
    local arch_lc tag="v${_GUM_VERSION}" url tmpdir
    arch_lc="$(uname -m)"
    case "$arch_lc" in
    x86_64) url="https://github.com/charmbracelet/gum/releases/download/${tag}/gum_${_GUM_VERSION}_Linux_x86_64.tar.gz" ;;
    aarch64) url="https://github.com/charmbracelet/gum/releases/download/${tag}/gum_${_GUM_VERSION}_Linux_arm64.tar.gz" ;;
    *)
        log::err "no upstream gum binary for arch ${arch_lc}"
        return 1
        ;;
    esac
    tmpdir="$(mktemp -d)"
    if ! curl -fsSL "$url" -o "${tmpdir}/gum.tgz"; then
        rm -rf "$tmpdir"
        log::err "could not download gum from ${url}"
        return 1
    fi
    tar -xzf "${tmpdir}/gum.tgz" -C "$tmpdir"
    mkdir -p "${HOME}/.local/bin"
    mv "${tmpdir}"/gum_*/gum "${HOME}/.local/bin/gum"
    chmod +x "${HOME}/.local/bin/gum"
    rm -rf "$tmpdir"
    export PATH="${HOME}/.local/bin:${PATH}"
}
