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
