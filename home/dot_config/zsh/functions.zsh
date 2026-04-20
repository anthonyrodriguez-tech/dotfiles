# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : interactive shell functions. Anything more than 3 lines that
#         needs $args goes here (vs. an alias).
# WHERE : home/dot_config/zsh/functions.zsh  →  ~/.config/zsh/functions.zsh
# WHY   : Functions get tab-completion (`zstyle :completion:`), aliases
#         do not. Also: aliases can't take positional args.
# ─────────────────────────────────────────────────────────────────────────────

# ── mkcd: mkdir -p + cd ───────────────────────────────────────────────────
mkcd() {
    [[ -z "$1" ]] && { print -u2 "mkcd: usage: mkcd <dir>"; return 1; }
    mkdir -p -- "$1" && cd -- "$1"
}

# ── fkill: fuzzy-pick a process and send it a signal (default TERM) ───────
#   fkill           → SIGTERM
#   fkill 9         → SIGKILL
fkill() {
    command -v fzf >/dev/null 2>&1 || { print -u2 "fkill: fzf required"; return 1; }
    local sig="${1:-15}"
    local pids
    pids=$(ps -ef | sed 1d | fzf -m --header="kill -$sig (TAB to multi-select)" | awk '{print $2}')
    [[ -z "$pids" ]] && return 0
    print -- "$pids" | xargs -r kill -"$sig"
}

# ── fbranch: fuzzy-pick a git branch (local + remote) and switch ──────────
fbranch() {
    command -v fzf >/dev/null 2>&1 || { print -u2 "fbranch: fzf required"; return 1; }
    git rev-parse --git-dir >/dev/null 2>&1 || { print -u2 "fbranch: not a git repo"; return 1; }
    local branch
    branch=$(
        git branch --all --color=never \
            | sed -e 's/^[* ] //' -e 's|^remotes/origin/||' \
            | grep -v -- '->' \
            | awk '!seen[$0]++' \
            | fzf --header='git switch'
    )
    [[ -z "$branch" ]] && return 0
    git switch "$branch" 2>/dev/null || git switch -c "$branch"
}

# ── extract: universal archive extractor ──────────────────────────────────
extract() {
    [[ -z "$1" ]] && { print -u2 "extract: usage: extract <archive>"; return 1; }
    [[ -f "$1" ]] || { print -u2 "extract: $1: not a regular file"; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2)  tar -xjf  "$1" ;;
        *.tar.gz|*.tgz)    tar -xzf  "$1" ;;
        *.tar.xz|*.txz)    tar -xJf  "$1" ;;
        *.tar.zst)         tar --zstd -xf "$1" ;;
        *.tar)             tar -xf   "$1" ;;
        *.bz2)             bunzip2   "$1" ;;
        *.gz)              gunzip    "$1" ;;
        *.xz)              unxz      "$1" ;;
        *.zip)             unzip     "$1" ;;
        *.7z)              7z x      "$1" ;;
        *.rar)             unrar x   "$1" ;;
        *)                 print -u2 "extract: don't know how to extract '$1'"; return 1 ;;
    esac
}
