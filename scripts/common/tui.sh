#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# WHAT  : interactive TUI that collects user choices and writes them to
#         ~/.config/chezmoi/chezmoi.toml — the per-machine data file
#         chezmoi reads at every `apply`. Gum-powered when available,
#         POSIX `read -r` fallback otherwise (proxy-locked machines).
# WHERE : scripts/common/tui.sh
# WHY   : the dotfiles framework is "plug & play": the user never edits
#         tracked templates by hand. The TUI is the single entry point
#         that turns user intent into chezmoi data; everything downstream
#         (.chezmoiignore, run_onchange_* hooks, cheatsheet) is driven
#         from those values.
#
# Usage:
#   . scripts/common/tui.sh        # source it
#   tui::run                       # interactive flow
#   tui::run --no-bootstrap        # just write the config, skip chezmoi
# ─────────────────────────────────────────────────────────────────────────

# Fail fast unless already in strict mode (lib.sh sets -euo pipefail).
set -euo pipefail

# Source lib.sh from the same dir (idempotent — guarded by sentinel).
if [ -z "${_DOTFILES_LIB_LOADED:-}" ]; then
    _TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=scripts/common/lib.sh
    . "${_TUI_DIR}/lib.sh"
    _DOTFILES_LIB_LOADED=1
fi

# ── Catalogues ────────────────────────────────────────────────────────────
# Source of truth = home/.chezmoidata.toml [editors_available] / [tools_available].
# We parse it dynamically so adding a tool there shows up in the TUI without
# touching this file. The TOML parser below only handles flat
# `key = "value"` pairs inside the targeted [section] — no nesting, which is
# all .chezmoidata.toml uses for these two sections.
readonly _TUI_PROFILES=(arch ubuntu safran)

# tui::_load_section <section-name> → echoes one "key|label" pair per line,
# in source order. Empty if the file or section is missing.
tui::_load_section() {
    local section="$1"
    local file
    if [ -n "${_TUI_DIR:-}" ] && [ -f "${_TUI_DIR}/../../home/.chezmoidata.toml" ]; then
        file="${_TUI_DIR}/../../home/.chezmoidata.toml"
    elif [ -f "${HOME}/.local/share/chezmoi/home/.chezmoidata.toml" ]; then
        file="${HOME}/.local/share/chezmoi/home/.chezmoidata.toml"
    else
        return 0
    fi
    awk -v sec="[$section]" '
        $0 == sec        { in_section = 1; next }
        /^\[/            { in_section = 0 }
        in_section && /^[a-zA-Z_][a-zA-Z0-9_-]*[[:space:]]*=/ {
            split($0, kv, "=")
            key = kv[1]
            sub(/[[:space:]]+$/, "", key)
            val = $0
            sub(/^[^=]*=[[:space:]]*/, "", val)
            sub(/^"/, "", val); sub(/"[[:space:]]*(#.*)?$/, "", val)
            printf "%s|%s\n", key, val
        }
    ' "$file"
}

_TUI_EDITORS_KEYS=()
_TUI_EDITORS_LABELS=()
_TUI_TOOLS_KEYS=()
_TUI_TOOLS_LABELS=()

tui::_init_catalogues() {
    local line key label
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        key="${line%%|*}"
        label="${line#*|}"
        _TUI_EDITORS_KEYS+=("$key")
        _TUI_EDITORS_LABELS+=("${key} — ${label}")
    done < <(tui::_load_section editors_available)

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        key="${line%%|*}"
        label="${line#*|}"
        _TUI_TOOLS_KEYS+=("$key")
        _TUI_TOOLS_LABELS+=("${key} — ${label}")
    done < <(tui::_load_section tools_available)

    # Hardcoded fallback if the data file is missing (curl-pipe before clone).
    if [ "${#_TUI_EDITORS_KEYS[@]}" -eq 0 ]; then
        _TUI_EDITORS_KEYS=(nvim code zed)
        _TUI_EDITORS_LABELS=(
            "nvim — Neovim (LazyVim)"
            "code — Visual Studio Code"
            "zed — Zed"
        )
    fi
    if [ "${#_TUI_TOOLS_KEYS[@]}" -eq 0 ]; then
        _TUI_TOOLS_KEYS=(docker dotnet node)
        _TUI_TOOLS_LABELS=(
            "docker — Docker Engine + CLI"
            "dotnet — .NET SDK"
            "node — Node.js (via mise)"
        )
    fi
}

# ── Gum wrappers (auto-fallback to POSIX prompts) ────────────────────────

_TUI_USE_GUM=0
tui::_init_gum() {
    if gum::ensure; then
        _TUI_USE_GUM=1
    else
        _TUI_USE_GUM=0
    fi
}

tui::input() {
    local label="$1" def="${2:-}"
    if [ "$_TUI_USE_GUM" = "1" ]; then
        gum input --prompt "${label}: " --value "$def" --placeholder "$def"
    else
        prompt::input "$label" "$def"
    fi
}

tui::choose_one() {
    local label="$1"
    shift
    if [ "$_TUI_USE_GUM" = "1" ]; then
        gum choose --header "$label" "$@"
    else
        prompt::choose "$label" "$@"
    fi
}

# tui::choose_many <label> <preselected-csv> <opt1> [<opt2> ...]
# Returns one selected option per line. Uses --selected for gum so the
# previous answers survive a re-run.
tui::choose_many() {
    local label="$1" preselected="$2"
    shift 2
    if [ "$_TUI_USE_GUM" = "1" ]; then
        if [ -n "$preselected" ]; then
            gum choose --no-limit --header "$label" --selected "$preselected" "$@"
        else
            gum choose --no-limit --header "$label" "$@"
        fi
    else
        prompt::multi_choose "$label" "$@"
    fi
}

# ── chezmoi data lookup (pre-fill) ───────────────────────────────────────

# tui::_chezmoi_field <jsonpath-key> [<default>] — best-effort read of an
# existing scalar field in `chezmoi data` JSON. Empty if chezmoi or jq is
# missing, or the field is absent.
tui::_chezmoi_field() {
    local key="$1" def="${2:-}" val=""
    if has_cmd chezmoi && has_cmd jq; then
        val="$(chezmoi data 2>/dev/null \
            | jq -r --arg k "$key" '.[$k] // empty' 2>/dev/null || true)"
    fi
    if [ -n "$val" ]; then
        printf '%s\n' "$val"
    elif [ -n "$def" ]; then
        printf '%s\n' "$def"
    fi
}

# tui::_chezmoi_array <key> — best-effort read of an array; outputs items
# space-separated (suitable for gum --selected).
tui::_chezmoi_array() {
    local key="$1"
    if has_cmd chezmoi && has_cmd jq; then
        chezmoi data 2>/dev/null |
            jq -r --arg k "$key" '(.[$k] // []) | join(",")' 2>/dev/null || true
    fi
}

# Map a chosen LABEL line back to its KEY ("code — Visual Studio Code" → "code")
tui::_label_to_key() {
    # First whitespace-delimited token, stripped of trailing '—'.
    awk '{print $1}' | sed 's/[[:space:]]*$//'
}

# tui::_keys_to_labels <comma-csv-keys> <label1> [<label2> ...]
# Returns the comma-joined subset of labels whose first token matches one of
# the input keys. Used to feed gum's `--selected` so pre-existing choices
# survive a re-run of the TUI.
tui::_keys_to_labels() {
    local keys_csv="$1"
    shift
    [ -z "$keys_csv" ] && return 0
    local labels=("$@") result=()
    local IFS=',' picked_keys
    read -ra picked_keys <<< "$keys_csv"
    unset IFS
    local label label_key k
    for label in "${labels[@]}"; do
        label_key="$(printf '%s' "$label" | awk '{print $1}')"
        for k in "${picked_keys[@]}"; do
            if [ "$label_key" = "$k" ]; then
                result+=("$label")
                break
            fi
        done
    done
    local OUT_IFS=','
    printf '%s' "${result[0]:-}"
    local i
    for ((i = 1; i < ${#result[@]}; i++)); do
        printf '%s%s' "$OUT_IFS" "${result[$i]}"
    done
    printf '\n'
}

# ── Atomic chezmoi.toml writer ───────────────────────────────────────────

# TOML basic-string quoting: escape backslash, double-quote, and wrap.
tui::_toml_quote() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '"%s"' "$s"
}

# tui::_toml_array <name> <var1> [<var2> ...]  — emits   name = ["a","b"]
tui::_toml_array() {
    local name="$1"
    shift
    printf '    %s = [' "$name"
    local first=1 v
    for v in "$@"; do
        [ -z "$v" ] && continue
        if [ "$first" = "1" ]; then
            first=0
            tui::_toml_quote "$v"
        else
            printf ', '
            tui::_toml_quote "$v"
        fi
    done
    printf ']\n'
}

tui::_write_chezmoi_toml() {
    local cfg_dir="${HOME}/.config/chezmoi"
    local cfg_file="${cfg_dir}/chezmoi.toml"
    mkdir -p "$cfg_dir"

    local tmp
    tmp="$(mktemp "${cfg_dir}/chezmoi.toml.XXXXXX")"
    {
        printf '# Written by scripts/common/tui.sh — edit via `chezmoi edit-config`\n'
        printf '# or re-run scripts/install.sh for the interactive flow.\n\n'
        printf '[data]\n'
        printf '    name        = %s\n' "$(tui::_toml_quote "$NAME")"
        printf '    email       = %s\n' "$(tui::_toml_quote "$EMAIL")"
        printf '    profile     = %s\n' "$(tui::_toml_quote "$PROFILE")"
        printf '    proxy_http  = %s\n' "$(tui::_toml_quote "${PROXY_HTTP:-}")"
        printf '    proxy_https = %s\n' "$(tui::_toml_quote "${PROXY_HTTPS:-}")"
        tui::_toml_array editors "${EDITORS[@]:-}"
        tui::_toml_array tools   "${TOOLS[@]:-}"
    } > "$tmp"

    mv "$tmp" "$cfg_file"
    log::ok "wrote ${cfg_file}"
}

# ── Main flow ─────────────────────────────────────────────────────────────

tui::run() {
    local skip_bootstrap=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --no-bootstrap) skip_bootstrap=1 ;;
            *) log::warn "tui::run: unknown flag $1" ;;
        esac
        shift
    done

    log::step "dotfiles bootstrap — interactive setup"
    tui::_init_catalogues
    tui::_init_gum

    # Pre-fill from any prior run.
    local prev_name prev_email prev_profile prev_editors prev_tools
    prev_name="$(tui::_chezmoi_field name)"
    prev_email="$(tui::_chezmoi_field email)"
    prev_profile="$(tui::_chezmoi_field profile)"
    prev_editors="$(tui::_chezmoi_array editors)"
    prev_tools="$(tui::_chezmoi_array tools)"

    # ── Identity ─────────────────────────────────────────────────────────
    NAME="$(tui::input "Full name" "$prev_name")"
    EMAIL="$(tui::input "Email" "$prev_email")"

    # ── Profile ──────────────────────────────────────────────────────────
    if [ -n "$prev_profile" ]; then
        log::ok "profile: ${prev_profile} (kept)"
        PROFILE="$prev_profile"
    else
        PROFILE="$(tui::choose_one "Machine profile" "${_TUI_PROFILES[@]}")"
    fi

    # ── Proxy (safran only) ──────────────────────────────────────────────
    PROXY_HTTP=""
    PROXY_HTTPS=""
    if [ "$PROFILE" = "safran" ]; then
        PROXY_HTTP="$(tui::input "HTTP proxy URL (blank if none)" "")"
        PROXY_HTTPS="$(tui::input "HTTPS proxy URL (blank if none)" "")"
    fi

    # ── Editors ──────────────────────────────────────────────────────────
    local editor_options=()
    local i
    local os
    os="$(os::detect)"
    for i in "${!_TUI_EDITORS_KEYS[@]}"; do
        # Hide Zed on Windows (no stable build).
        if [ "${_TUI_EDITORS_KEYS[$i]}" = "zed" ] && [ "$os" = "windows" ]; then
            continue
        fi
        editor_options+=("${_TUI_EDITORS_LABELS[$i]}")
    done

    local prev_editor_labels
    prev_editor_labels="$(tui::_keys_to_labels "$prev_editors" "${editor_options[@]}")"

    local raw_editors
    raw_editors="$(tui::choose_many \
        "Editors to install (Space to toggle, Enter to confirm)" \
        "$prev_editor_labels" \
        "${editor_options[@]}")"

    EDITORS=()
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        EDITORS+=("$(printf '%s' "$line" | tui::_label_to_key)")
    done <<< "$raw_editors"

    # ── Tools ────────────────────────────────────────────────────────────
    local prev_tool_labels
    prev_tool_labels="$(tui::_keys_to_labels "$prev_tools" "${_TUI_TOOLS_LABELS[@]}")"

    local raw_tools
    raw_tools="$(tui::choose_many \
        "Additional tools" \
        "$prev_tool_labels" \
        "${_TUI_TOOLS_LABELS[@]}")"

    TOOLS=()
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        TOOLS+=("$(printf '%s' "$line" | tui::_label_to_key)")
    done <<< "$raw_tools"

    # ── Persist + chezmoi ────────────────────────────────────────────────
    tui::_write_chezmoi_toml

    if [ "$skip_bootstrap" = "1" ]; then
        log::ok "config written — chezmoi bootstrap skipped (--no-bootstrap)"
        return 0
    fi

    local repo_url="${DOTFILES_REPO:-https://github.com/tony/dotfiles.git}"
    chezmoi_bootstrap "$repo_url"
}

# Allow running as a script too: `bash scripts/common/tui.sh`
if [ "${BASH_SOURCE[0]}" = "${0:-}" ]; then
    tui::run "$@"
fi
