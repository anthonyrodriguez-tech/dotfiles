# ─────────────────────────────────────────────────────────────────────────────
# WHAT  : zsh shell options. Affects globbing, prompt expansion, job control.
# WHERE : home/dot_config/zsh/options.zsh  →  ~/.config/zsh/options.zsh
# WHY   : Sourced first so every later module sees consistent semantics
#         (e.g. EXTENDED_GLOB enables ^ and (#qN…) used in completion.zsh).
# ─────────────────────────────────────────────────────────────────────────────

setopt AUTO_CD                # `foo` ≡ `cd foo` if foo is a dir
setopt AUTO_PUSHD             # cd pushes onto dirstack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB          # ^, ~, # globs and glob qualifiers
setopt GLOB_DOTS              # globs match dotfiles too
setopt INTERACTIVE_COMMENTS   # `# foo` works at the prompt
setopt NO_BEEP
setopt PROMPT_SUBST           # allow ${…} expansion in PROMPT (starship needs it)
setopt LONG_LIST_JOBS
setopt NOTIFY                 # report background-job status immediately
setopt NO_FLOW_CONTROL        # free Ctrl-S / Ctrl-Q for keybinds
