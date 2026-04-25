# dotfiles

> Cross-platform dotfiles for **Arch Linux**, **Ubuntu/Debian** and **Windows** (native, via Scoop + MSYS2).
> Managed with [chezmoi](https://www.chezmoi.io/) for per-machine templating.

[![CI](https://github.com/tony/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/tony/dotfiles/actions/workflows/ci.yml)
![chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue)
[![license](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

## Table of contents

- [Stack](#stack)
- [Install](#install)
- [Maintenance](#maintenance)
- [Uninstall](#uninstall)
- [Structure](#structure)
- [Per-machine profiles](#per-machine-profiles)
- [Documentation](#documentation)

## Stack

| Layer | Tool |
|---|---|
| Dotfile manager | chezmoi |
| Shell | zsh (everywhere, incl. MSYS2 on Windows) |
| Terminal | WezTerm (Ghostty planned) |
| Prompt | Starship |
| Editor | Neovim + LazyVim |
| Git UI | Lazygit |
| AI in terminal | Claude Code + oh-my-pi (`omp`) |
| Package manager | pacman (arch) · apt (ubuntu) · Scoop (windows, user-level) |

See [`docs/plan-history.md`](./docs/plan-history.md) for the full implementation plan and rationale.

## Install

> Each bootstrap script is idempotent — re-running it does nothing if everything is already in place.

### Arch Linux

```sh
curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-arch.sh | bash
```

### Ubuntu / Debian

```sh
curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-ubuntu.sh | bash
```

### Windows (PowerShell, no admin required)

```powershell
irm https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-windows.ps1 | iex
```

Each bootstrap script is **idempotent** (re-run safely) and needs no admin
rights — Linux uses the native package manager (pacman or apt), Windows
uses Scoop + MSYS2 under `%USERPROFILE%`.

If you prefer to skip the bootstrap and just wire up dotfiles into an
already-prepared system:

```sh
chezmoi init --apply https://github.com/<USER>/dotfiles.git
```

### Post-install — AI CLIs

After the first `chezmoi apply`, the Claude Code settings / agents / global
CLAUDE.md land in `~/.claude/`. Sign in once from any terminal:

```sh
claude          # first launch prompts for browser login
omp             # configure providers via /login (omp reads ~/.claude/ natively)
```

Subsequent `chezmoi apply` runs do not overwrite auth tokens — credentials
live outside chezmoi's tracked state.

## Maintenance

The dotfiles ship two binaries on `$PATH` for day-to-day upkeep:

```sh
dotfiles-update            # full pass: pkg upgrade + chezmoi + LazyVim + Mason + AI CLIs
dotfiles-update --quick    # minimal: chezmoi update + nvim Lazy sync only
dotfiles-update --no-pkg   # skip system package upgrade (useful behind a flaky proxy)

dotfiles-doctor            # health check: binaries on PATH, nvim startup, chezmoi diagnostics
dotfiles-doctor --quiet    # only show problems (good for CI)
```

On Windows, `dotfiles-update.ps1` and `dotfiles-doctor.ps1` are also deployed
for users who live in PowerShell instead of MSYS2 zsh.

The full update pass runs, in order:
1. System package upgrade (`pacman -Syu` / `apt upgrade` / `scoop update *`)
2. `chezmoi update --apply` (pull repo + apply changes)
3. `mise upgrade` (toolchain runtimes)
4. `nvim --headless +"Lazy! sync" +qa` (LazyVim plugins)
5. `nvim --headless +MasonUpdate +qa` (LSP / formatters / linters)
6. `bun update -g @oh-my-pi/pi-coding-agent` (omp, if bun present)
7. `claude update` (if supported by the installed version)
8. `zinit self-update && zinit update --all`

## Uninstall

Each platform has a **safe-mode** uninstall script that removes the
dotfiles layer without touching shared system packages:

```sh
./scripts/uninstall-arch.sh           # Arch — chezmoi purge + remove user binaries + chsh bash
./scripts/uninstall-ubuntu.sh         # Ubuntu — same shape
.\scripts\uninstall-windows.ps1       # Windows — chezmoi purge + scoop apps installed by bootstrap
.\scripts\uninstall-windows.ps1 -Full # Windows — also remove Scoop entirely
```

The Linux scripts intentionally do **not** remove pacman/apt packages, since
they're shared with the rest of the system. Run `pacman -Rns ...` or
`apt remove ...` manually if you want a full wipe.

## Structure

```
dotfiles/
├── home/                       chezmoi source state (target = $HOME)
│   ├── dot_config/             → ~/.config/
│   │   ├── zsh/                modular zsh (path / env / history / plugins…)
│   │   ├── wezterm/            tmux-like keybindings, cross-OS shell detection
│   │   ├── starship.toml
│   │   ├── nvim/               LazyVim + .NET / DevOps overlay
│   │   ├── lazygit/
│   │   ├── ripgrep/
│   │   └── tmux/               (used everywhere except Windows)
│   ├── dot_claude/             → ~/.claude/  (settings, agents, commands)
│   ├── dot_local/bin/          dotfiles-update, dotfiles-doctor (POSIX + .ps1)
│   └── dot_gitconfig.tmpl      → ~/.gitconfig (templated identity)
├── scripts/                    bootstrap-{arch,ubuntu,windows}, uninstall-*, common/lib.sh
└── docs/                       ADRs, cheatsheets, troubleshooting, plan history
```

## Per-machine profiles

`chezmoi init` prompts for a `profile`, which conditions templated files:

| Profile | Use case |
|---|---|
| `arch`   | personal Arch Linux machine |
| `ubuntu` | personal Ubuntu / Debian machine |
| `safran` | Safran corporate Windows laptop (MSYS2, proxy, restricted permissions) |

Local non-tracked overrides:
- `~/.config/zsh/local.zsh` — sourced last by zsh
- `~/.gitconfig.local` — included by `~/.gitconfig`

## Documentation

- [`docs/install.md`](./docs/install.md) — what the bootstrap installs, manual steps, verification
- [`docs/cheatsheet.md`](./docs/cheatsheet.md) — WezTerm / Neovim / Lazygit / zsh keybindings and aliases
- [`docs/troubleshooting.md`](./docs/troubleshooting.md) — clipboard, MSYS2 quirks, chezmoi prompt gotchas
- [`docs/decisions.md`](./docs/decisions.md) — architecture decision records
- [`docs/migration-to-ghostty.md`](./docs/migration-to-ghostty.md) — planned WezTerm → Ghostty port
- [`docs/plan-history.md`](./docs/plan-history.md) — phased implementation plan (historical)
