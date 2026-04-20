# Architecture Decision Records

Light-weight ADRs. Each entry: **context**, **decision**, **consequences**.
Append new ones at the bottom; never edit historical entries — supersede
with a new ADR instead.

---

## ADR-001 — chezmoi over GNU stow / yadm / bare-git

**Context.** Three target machines (macOS perso, Safran Windows, Geneva)
with diverging identities (email, git config) and diverging tool
availability (no admin on Safran, no `eza`/`zoxide` packaged on MSYS2).
A pure symlink farm (`stow`) cannot template per-machine values.

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
OS — Safran could theoretically run on macOS too one day.

**Decision.** Introduce a `profile` prompt at `chezmoi init` with four
fixed values:

| `.profile`  | Use case |
|-------------|----------|
| `personal`  | Personal hardware, no corporate constraints |
| `safran`    | Safran corporate laptop (Windows + MSYS2, proxy, restricted Claude permissions, work email) |
| `geneva`    | Geneva work laptop |
| `homelab`   | Linux server / VM (headless, no terminal/wezterm needed) |

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
* Adding a fifth profile means editing the `list` in
  `.chezmoi.toml.tmpl` — keep the set small on purpose, otherwise the
  conditionals scatter.
* `.profile` is **not** auto-detectable from the OS. If you re-image a
  machine and forget to set it, prompts re-fire on `chezmoi init`.

### When to use `.profile` vs `.chezmoi.os` vs `.chezmoi.hostname`

* `.chezmoi.os` (`darwin` / `linux` / `windows`) — purely technical
  branches (which package manager, which shebang, clipboard tool).
* `.profile` — *policy* / identity branches (which email, which proxy,
  which Claude permissions, whether to ship a work-only agent).
* `.chezmoi.hostname` — escape hatch for one-machine quirks; avoid
  unless the conditional truly applies to a single host.

Rule of thumb: if the answer to "should this branch survive after I
re-image this exact machine?" is *yes* → use `.profile`. If
*hostname-specific* → `.chezmoi.hostname`.

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
* Muscle memory ports 1:1 between mac and Windows.
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
Salt (overkill for 4 laptops), cloud-init (Linux-only), hand-rolled
bash / PowerShell.

**Decision.** Hand-rolled idempotent scripts under `scripts/`:
`bootstrap-{mac,linux,windows}` + shared `common/lib.sh`. Each script
wraps the OS-native package manager (Homebrew / apt+dnf+pacman / Scoop)
and ends with `chezmoi init --apply`.

**Consequences.**
* Readable: no runtime layer, the script *is* the install plan.
* Safe re-runs: every install step is guarded (`brew list`,
  `scoop install` is itself idempotent).
* Windows refuses to run elevated — Scoop would corrupt its state if it
  did.
* Trade-off: 3 scripts to maintain instead of one; acceptable given
  each OS has genuinely different tooling.
