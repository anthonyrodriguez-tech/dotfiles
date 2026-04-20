# dotfiles

> Cross-platform dotfiles for **macOS**, **Linux** and **Windows** (native, via Scoop + MSYS2).
> Managed with [chezmoi](https://www.chezmoi.io/) for per-machine templating.

<!-- badges: placeholders, wired up in Phase 11 (CI) -->
![CI](https://img.shields.io/badge/ci-pending-lightgrey)
![chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue)
![license](https://img.shields.io/badge/license-MIT-green)

## Table of contents

- [Stack](#stack)
- [Install](#install)
- [Update](#update)
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
| AI in terminal | Claude Code |
| Package manager | brew (mac) · apt/dnf/pacman (linux) · Scoop (windows, user-level) |

See [`PLAN.md`](./PLAN.md) for the full implementation plan and rationale.

## Install

> Each bootstrap script is idempotent — re-running it does nothing if everything is already in place.

### macOS

```sh
curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-mac.sh | bash
```

### Linux (apt / dnf / pacman auto-detected)

```sh
curl -fsSL https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-linux.sh | bash
```

### Windows (PowerShell, no admin required)

```powershell
irm https://raw.githubusercontent.com/<USER>/dotfiles/main/scripts/bootstrap-windows.ps1 | iex
```

> ⚠ Phase 0 — bootstrap scripts are placeholders. They land in **Phase 9**.
> Until then, install [chezmoi](https://www.chezmoi.io/install/) manually and run:
>
> ```sh
> chezmoi init --apply https://github.com/<USER>/dotfiles.git
> ```

### Post-install — Claude Code

After the first `chezmoi apply`, the Claude Code settings / agents / global CLAUDE.md
land in `~/.claude/`. Sign in once from any terminal:

```sh
claude auth login
```

Subsequent `chezmoi apply` runs will not overwrite the auth token — it lives in
`~/.claude/.credentials.json` which is not managed by chezmoi.

## Update

```sh
chezmoi update             # pull repo + apply changes
chezmoi diff               # preview pending changes
chezmoi apply -v           # apply with verbose output
chezmoi cd                 # drop into the source repo
```

## Structure

```
dotfiles/
├── home/                    chezmoi source state (target = $HOME)
│   ├── dot_config/          → ~/.config/
│   │   ├── zsh/             modular zsh (path / env / history / plugins…)
│   │   ├── wezterm/         tmux-like keybindings, cross-OS shell detection
│   │   ├── starship.toml
│   │   ├── nvim/            LazyVim + .NET / DevOps overlay
│   │   ├── lazygit/
│   │   ├── ripgrep/
│   │   └── tmux/            (used everywhere except Windows)
│   ├── dot_claude/          → ~/.claude/  (settings, agents, commands)
│   ├── dot_gitconfig.tmpl   → ~/.gitconfig (templated identity)
│   └── dot_local/bin/       portable scripts on $PATH
├── scripts/                 bootstrap-{mac,linux,windows}, not chezmoi-managed
├── docs/                    ADRs, cheatsheets, troubleshooting
└── PLAN.md                  implementation roadmap (phases 0–11)
```

## Per-machine profiles

`chezmoi init` prompts for a `profile`, which conditions templated files:

| Profile | Use case |
|---|---|
| `personal` | personal laptop (macOS) |
| `safran` | Safran corporate laptop (Windows + MSYS2, proxy, restricted) |
| `geneva` | Geneva work laptop |
| `homelab` | linux server / VM |

Local non-tracked overrides:
- `~/.config/zsh/local.zsh` — sourced last by zsh
- `~/.gitconfig.local` — included by `~/.gitconfig`

## Documentation

- [`PLAN.md`](./PLAN.md) — phased implementation plan
- `docs/decisions.md` — architecture decision records (Phase 10)
- `docs/cheatsheet.md` — keybindings reference (Phase 10)
- `docs/troubleshooting.md` — common issues (Phase 10)
- `docs/migration-to-ghostty.md` — future migration plan (Phase 10)
