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
