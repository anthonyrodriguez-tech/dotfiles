# Architecture Decision Records

Light-weight ADRs. Each entry: **context**, **decision**, **consequences**.
Append new ones at the bottom; never edit historical entries — supersede
with a new ADR instead.

---

## ADR-001 — chezmoi over GNU stow / yadm / bare-git

**Context.** Three target machines (Arch perso, Ubuntu perso, Safran
Windows) with diverging identities (email, git config) and diverging
tool availability (no admin on Safran, no `eza`/`zoxide` packaged on
MSYS2). A pure symlink farm (`stow`) cannot template per-machine values.

**Decision.** Use **chezmoi** as the dotfile manager. Source state lives
under `home/` in this repo; `chezmoi init --source=$(pwd)/home --apply`
materialises `$HOME` on a fresh box.

**Consequences.**
* Native cross-OS (Windows-first, not Unix-only).
* Templating with Go templates → conditionals on `.profile`,
  `.chezmoi.os`, `.chezmoi.hostname`.
* Single binary, no runtime dependency in $HOME.
* Trade-off: contributors need to learn chezmoi's `dot_` / `private_` /
  `executable_` source-name conventions.

---

## ADR-002 — Profiles as the primary templating axis

**Context.** Some divergence is per-OS (clipboard helper, package
manager) and chezmoi already exposes `.chezmoi.os` for that. But
*organisational* divergence (corporate proxy at Safran, restricted
Claude Code permissions, work email vs perso email) is orthogonal to
OS — Safran could theoretically run on Linux too one day.

**Decision.** Introduce a `profile` prompt at `chezmoi init` with three
fixed values:

| `.profile`  | Use case |
|-------------|----------|
| `arch`      | Personal Arch Linux machine |
| `ubuntu`    | Personal Ubuntu / Debian machine |
| `safran`    | Safran corporate Windows laptop (MSYS2, proxy, restricted Claude permissions, work email) |

The choice is captured once in `home/.chezmoi.toml.tmpl` via
`promptChoiceOnce`, persisted into `~/.config/chezmoi/chezmoi.toml`,
then read everywhere else as `.profile`.

**Consequences.**
* New machine = answer 3 prompts (email, name, profile), nothing else.
* Templates can branch with the standard chezmoi pattern:
  ```
  {{- if eq .profile "safran" -}}
  # corporate proxy block
  {{- end -}}
  ```
* Adding a fourth profile means editing the `list` in
  `.chezmoi.toml.tmpl` — keep the set small on purpose, otherwise the
  conditionals scatter.
* `.profile` is **not** auto-detectable from the OS. If you re-image a
  machine and forget to set it, prompts re-fire on `chezmoi init`.

### When to use `.profile` vs `.chezmoi.os` vs `.chezmoi.hostname`

* `.chezmoi.os` (`linux` / `windows`) — purely technical branches
  (which package manager, which shebang, clipboard tool).
* `.profile` — *policy* / identity branches (which email, which proxy,
  which Claude permissions, whether to ship a work-only agent).
* `.chezmoi.hostname` — escape hatch for one-machine quirks; avoid
  unless the conditional truly applies to a single host.

Rule of thumb: if the answer to "should this branch survive after I
re-image this exact machine?" is *yes* → use `.profile`. If
*hostname-specific* → `.chezmoi.hostname`.

**Supersedes** the original 4-profile scheme (`personal`, `safran`,
`geneva`, `homelab`) — the macOS / Geneva work laptop / homelab targets
were dropped in favour of focusing on the three live machines.

---

## ADR-003 — zsh everywhere (incl. Windows via MSYS2)

**Context.** Three shell candidates: bash (lowest common denominator),
zsh (mature plugin ecosystem, `fzf-tab`, `zinit`), nushell (structured
data but domain-specific). The corporate Windows machine has no admin
and no WSL2.

**Decision.** zsh on every OS, provided by MSYS2 on Windows. Config
lives under `$XDG_CONFIG_HOME/zsh/` and is split into 10 modules loaded
in a deterministic order (options → env → history → path → completion →
plugins → keybinds → aliases → functions → integrations). OS-specific
logic is a runtime `$DOTFILES_OS` switch (uname-based), not a chezmoi
template, so the files are identical on every machine.

**Consequences.**
* Muscle memory ports 1:1 between Linux and Windows.
* MSYS2 reality checks needed on every `command -v` for tools that may
  not be available (`eza`, `zoxide`, `fzf`) — see `aliases.zsh`.
* Plugin load order matters: `compinit` must run *after* zsh-completions
  extends fpath and *before* fzf-tab / syntax-highlighting register
  hooks. See `plugins.zsh`.
* Switching to nushell later is a non-trivial rewrite; captured as an
  ADR supersession if/when it happens.

---

## ADR-004 — LazyVim as the Neovim distribution

**Context.** Raw Neovim config from scratch is ~40 h of upfront work
plus constant maintenance. LunarVim, AstroNvim, LazyVim are the three
mainstream distros. The editor target is .NET + Terraform + shell + Lua
(this config itself), all with LSP + formatter + DAP.

**Decision.** LazyVim as the base, with a thin overlay in
`lua/plugins/*.lua` for DevOps-specific additions (omnisharp + dap for
.NET, schemastore.nvim for YAML, harpoon2, terraform-tools). Overrides
use the `opts = function(_, opts) ... return opts end` pattern so we
never lose LazyVim's defaults.

**Consequences.**
* Upgrades come from upstream; we inherit bug fixes and plugin
  refreshes without touching our config.
* Trade-off: when LazyVim renames a key or moves a plugin, our overlay
  may silently drop to a no-op. Caught by `:checkhealth` and the
  post-install test (`nvim --headless` require of every module).
* `lazy-lock.json` policy: **commit it**. It pins plugin SHAs so every
  machine starts identical; un-pinning is a conscious `:Lazy update`
  action, not drift.

---

## ADR-005 — Catppuccin Mocha as the project-wide palette

**Context.** Six visible surfaces (WezTerm, Starship, Neovim, Lazygit,
bat, delta) means six colour configs. Maintaining a bespoke palette
across them is an aesthetic tax without value.

**Decision.** Catppuccin Mocha everywhere, with hex codes duplicated
inline in each config rather than pulled from a central template.
Palettes don't change often and a per-tool file is simpler to audit
than a generator.

**Consequences.**
* Visual coherence across the terminal, editor, prompt, git UI.
* If Catppuccin ever ships a v2 with shifted values, it's a find-replace
  across ~6 files — acceptable cost.
* JetBrainsMono Nerd Font is the only font dependency; installed by all
  three bootstrap scripts.

---

## ADR-006 — Bootstrap scripts over cloud-init / Ansible

**Context.** "Fresh machine to working env in 20 min" requires an
automated entry point. Options: Ansible (heavy, needs Python), Puppet/
Salt (overkill for 3 laptops), cloud-init (Linux-only), hand-rolled
bash / PowerShell.

**Decision.** Hand-rolled idempotent scripts under `scripts/`:
`bootstrap-{arch,ubuntu,windows}` + shared `common/lib.sh`. Each script
wraps the OS-native package manager (pacman / apt / Scoop) and ends with
`chezmoi init --apply`. Each install script has a paired safe-mode
`uninstall-*` script.

**Consequences.**
* Readable: no runtime layer, the script *is* the install plan.
* Safe re-runs: every install step is guarded (`pacman -S --needed`,
  `scoop install` is itself idempotent).
* Windows refuses to run elevated — Scoop would corrupt its state if it
  did.
* Trade-off: 3 install scripts × 3 uninstall scripts to maintain instead
  of one each; acceptable given each OS has genuinely different tooling.

---

## ADR-007 — oh-my-pi (`omp`) alongside Claude Code

**Context.** Claude Code is the primary AI agent in the terminal. A new
fork of `badlogic/pi-mono`, [oh-my-pi](https://github.com/can1357/oh-my-pi),
adds features Claude Code doesn't ship (multi-provider routing,
hashline edits, native TypeScript slash commands, web-search providers,
TTSR rules, Cursor OAuth bridge). Worth having both side-by-side.

**Decision.** Install `omp` from the official upstream installer in all
three bootstrap scripts (POSIX `install.sh` on Linux, `install.ps1` on
Windows). No omp-specific config is shipped — `omp` natively reads
`~/.claude/commands/`, `~/.claude/agents/` and `~/.claude/CLAUDE.md`,
so the existing Claude Code config is reused as-is.

**Consequences.**
* Two AI CLIs available: `claude` and `omp`. User picks per-task.
* Zero config duplication — change `~/.claude/CLAUDE.md` and both
  agents pick it up.
* Update path: `bun update -g @oh-my-pi/pi-coding-agent` if bun is
  installed (Arch ships it; on Ubuntu/Windows the binary installer
  must be re-run to upgrade).
* Uninstall scripts remove `omp` from `~/.local/bin` but keep `~/.omp/`
  (sessions, credentials) — same policy as `~/.claude/`.

---

## ADR-008 — `dotfiles-update` and `dotfiles-doctor` shipped as dotfiles

**Context.** `chezmoi update` only refreshes dotfile content. Keeping
the rest of the stack current (LazyVim plugins, Mason packages, mise
runtimes, AI CLIs, system packages) requires running 5–6 separate
commands. Easy to skip a layer; easy to forget the right order.

**Decision.** Ship two binaries via chezmoi to `~/.local/bin/`:

* **`dotfiles-update`** — single entry point that runs the full
  maintenance pass (system pkg upgrade → chezmoi update → mise upgrade
  → Lazy sync → Mason update → omp/claude updates → zinit update).
  Flags: `--quick` (chezmoi + Lazy sync only), `--no-pkg` (skip system
  upgrade — useful behind a flaky proxy).
* **`dotfiles-doctor`** — health check (every expected binary on
  `$PATH`, `nvim --headless +qa` startup smoke, `chezmoi doctor`,
  presence of `~/.gitconfig.local` etc.). Exits non-zero if anything
  required is missing.

Both scripts are POSIX-bash (works on Linux + MSYS2 zsh) and have
`.ps1` siblings for users who live in PowerShell.

**Consequences.**
* "Update everything" becomes one command, runnable from anywhere.
* The maintenance recipe lives next to the dotfiles it maintains —
  if a tool is added to the stack, both bootstrap and update get the
  new step in the same PR.
* `dotfiles-doctor` doubles as the test surface for adding new tools:
  if you don't add the binary to its expected list, it shows up as
  `MISS` even when installed.
* Trade-off: 4 maintenance scripts (2 POSIX + 2 PS1). Mitigated by the
  fact they're parallel implementations of the same flow, not two
  divergent code-paths.
