# dotfiles

> **Plug & Play** multi-OS dotfiles framework — Arch Linux, Ubuntu/Debian,
> Windows (Scoop + MSYS2, no admin). Interactive bootstrap via the
> [gum](https://github.com/charmbracelet/gum) TUI, OS-dispatched install
> matrix, absolute idempotence, strict Core / User Space separation.

[![CI](https://github.com/tony/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/tony/dotfiles/actions/workflows/ci.yml)
![chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue)
[![license](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

---

## Table of contents

- [Why this repo](#why-this-repo)
- [Flow overview](#flow-overview)
- [Quick start](#quick-start)
- [Stack](#stack)
- [Tool catalogue](#tool-catalogue)
- [Per-machine profiles](#per-machine-profiles)
- [User Space — local overrides](#user-space--local-overrides)
- [Bundled CLI binaries](#bundled-cli-binaries)
- [Secrets workflow — SOPS + age](#secrets-workflow--sops--age)
- [Maintenance](#maintenance)
- [Architecture](#architecture)
- [Quality — multi-OS CI](#quality--multi-os-ci)
- [Uninstall](#uninstall)
- [Repo layout](#repo-layout)
- [Detailed documentation](#detailed-documentation)

---

## Why this repo

Three non-negotiable properties:

1. **Plug & Play.** One curl-able URL per OS. The script detects the
   distro, asks 5 questions through gum (name, email, profile, editors,
   tools), writes `~/.config/chezmoi/chezmoi.toml`, runs `chezmoi apply`.
   No manual edit of any tracked file.
2. **Absolute idempotence.** Re-running the install — or any
   `chezmoi apply` — never breaks anything. The `run_onchange_*` hooks
   re-install packages only when selections change (data-hash header in
   each script). CI asserts this on every PR.
3. **Core / User Space separation.** Personal overrides live in local
   files (`~/.zshrc.local`, `~/.gitconfig.local`,
   `~/.config/zsh/local.zsh`) that are never tracked. The repo stays
   generic; your identity stays yours.

---

## Flow overview

```
                                   curl install.sh | bash
                                            │
                                            ▼
       ┌─────────────────────  scripts/install.sh  ─────────────────────┐
       │  detect OS  →  clone repo  →  exec bootstrap-{arch,ubuntu}.sh  │
       └────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
        ┌──────────  bootstrap-<distro>.sh  ──────────┐
        │  install prerequisites (zsh, git, chezmoi…) │
        │  source scripts/common/tui.sh               │
        │  tui::run                                   │
        └─────────────────────────────────────────────┘
                                            │
                                            ▼
         ┌───────────  scripts/common/tui.sh  ────────────┐
         │  ensure gum (fallback: POSIX prompts)          │
         │  read prior chezmoi data → pre-tick choices    │
         │  prompts: name / email / profile / editors /   │
         │           tools                                │
         │  writes ~/.config/chezmoi/chezmoi.toml         │
         │  → chezmoi_bootstrap (init --apply)            │
         └────────────────────────────────────────────────┘
                                            │
                                            ▼
       ┌─────────────────  chezmoi apply  ─────────────────┐
       │  .chezmoiignore: OS gating + opt-in editors      │
       │  templates: VSCode, Zed, .gitconfig, CHEATSHEET  │
       │  run_onchange_10: install packages (PM → mise)   │
       │  run_onchange_20: install VSCode extensions      │
       └──────────────────────────────────────────────────┘
                                            │
                                            ▼
                              system ready — re-run safe
```

---

## Quick start

### Linux (Arch · Ubuntu · Debian)

```sh
curl -fsSL https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.sh | bash
```

### Windows (PowerShell, no admin)

```powershell
irm https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.ps1 | iex
```

### Local (already cloned)

```sh
./scripts/install.sh        # Linux
.\scripts\install.ps1       # Windows
```

### Manual (chezmoi only, no TUI)

To plug the dotfiles onto an already-prepared system, without gum:

```sh
chezmoi init --apply https://github.com/tony/dotfiles.git
```

The native chezmoi prompts take over (`.chezmoi.toml.tmpl` asks for
email/name/profile). `editors` and `tools` stay empty — minimal install,
no editor or extra tool. Round it out later with `dotfiles-config`.

---

## Stack

| Layer | Tool |
|---|---|
| Dotfile manager | [chezmoi](https://www.chezmoi.io/) |
| Bootstrap TUI | [gum](https://github.com/charmbracelet/gum) (POSIX fallback) |
| Shell | zsh (everywhere, MSYS2 included) |
| Terminal | WezTerm |
| Prompt | Starship |
| Default editor | Neovim + LazyVim |
| Git UI | Lazygit |
| AI in terminal | Claude Code + oh-my-pi (`omp`) |
| Runtimes | mise (universal) |
| Package manager | pacman / apt / Scoop |

---

## Tool catalogue

The TUI offers two groups: **editors** (multi-select) and **additional
tools** (multi-select). Source of truth = `home/.chezmoidata.toml`.

### Editors

| Key | Description | Tracked configuration |
|---|---|---|
| `nvim` | Neovim + LazyVim | `home/dot_config/nvim/` |
| `code` | Visual Studio Code | `home/dot_config/Code/User/settings.json.tmpl` (Linux/macOS) + `home/AppData/Roaming/Code/User/settings.json.tmpl` (Windows). Both pull from `home/.chezmoitemplates/vscode-settings.json`. |
| `zed` | Zed (Linux/macOS only) | `home/dot_config/zed/settings.json.tmpl` |

### Tools

| Category | Tools |
|---|---|
| Runtimes & desktop | `docker`, `dotnet`, `node` |
| Kubernetes & GitOps | `kubectl`, `helm`, `k9s`, `kustomize`, `argocd` |
| Infrastructure as Code | `terraform`, `terragrunt`, `ansible` |
| Secrets & encryption | `sops`, `age` |
| Cloud SDKs | `aws`, `az`, `gcloud` |

### Install strategy

`run_onchange_10-install-packages.sh.tmpl` dispatches in this order:

1. **Native PM** — `[packages.<tool>.<os>]` non-empty → `pacman` / `apt` / `scoop`.
2. **mise plugin** — `[mise_plugins.<tool>]` defined → `mise use --global <plugin>@latest`.
3. **Skip + warn** — otherwise, explicit log (tool not installable on this OS).

Consequence: `kubectl` on Ubuntu (no vanilla apt package) automatically
falls through to `mise`. No distro-specific branch for the user to
maintain.

---

## Per-machine profiles

The TUI asks for a `profile` that conditions templates:

| Profile | Use case |
|---|---|
| `arch` | Personal Arch Linux machine |
| `ubuntu` | Personal Ubuntu / Debian machine |
| `safran` | Corporate Windows laptop (MSYS2, proxy, restricted permissions) |

To add a custom profile: edit `home/.chezmoi.toml.tmpl` (the
`promptChoiceOnce` choices list) and `scripts/common/tui.sh`
(`_TUI_PROFILES`).

---

## User Space — local overrides

> **Never edit a tracked file to customize your environment.** The hooks
> below exist for exactly that.

| Concern | File (never tracked) | Mechanism |
|---|---|---|
| Personal zsh aliases / functions | `~/.config/zsh/local.zsh` | Sourced last by `.zshrc` |
| Personal zsh env vars | `~/.zshrc.local` | Sourced last by `.zshrc` |
| Git identity / signing key | `~/.gitconfig.local` | `[include]` at the bottom of `~/.gitconfig` |
| Git identity for `~/work/*` | `~/.gitconfig.work` | `[includeIf "gitdir:~/work/"]` |
| age private key (SOPS) | `~/.config/sops/age/keys.txt` | `$SOPS_AGE_KEY_FILE` exported |

### Changing your selections after install

```sh
dotfiles-config         # re-runs the gum TUI
                        # → re-writes ~/.config/chezmoi/chezmoi.toml
                        # → chezmoi apply (by default)
```

The `# data-hash:` header at the top of every `run_onchange_*.sh.tmpl`
changes when your data changes → chezmoi automatically replays the
install of new tools.

---

## Bundled CLI binaries

All deployed to `~/.local/bin/` (on PATH) by chezmoi.

```sh
dotfiles-update            # full pass: pkg upgrade + chezmoi update + LazyVim + Mason + AI CLIs
dotfiles-update --quick    # minimal: chezmoi update + nvim Lazy sync
dotfiles-update --no-pkg   # skip system package upgrade (flaky proxy)

dotfiles-doctor            # health check: binaries, nvim startup, chezmoi diagnostics
dotfiles-doctor --quiet    # only errors (CI-friendly)

dotfiles-config            # re-run the gum TUI (change editors / tools / profile)
dotfiles-config --no-apply # only writes chezmoi.toml, does not run apply

dotfiles-keygen-age        # bootstrap an age keypair for SOPS (one-shot)
dotfiles-keygen-age --pub  # re-print the public key (paste into .sops.yaml)
```

PowerShell variants ship for users who live in pwsh rather than MSYS2
zsh: `dotfiles-update.ps1`, `dotfiles-doctor.ps1`, `dotfiles-config.ps1`.

---

## Secrets workflow — SOPS + age

A ready-to-use encrypted-secrets stack for GitOps / IaC where secrets
are encrypted in-place inside the repo.

### Initial setup (one-shot)

```sh
dotfiles-keygen-age
# → creates ~/.config/sops/age/keys.txt (chmod 600), parent dir 700
# → prints the age1XXX… public key to paste into .sops.yaml
```

> **Mandatory backup** of the private key (`~/.config/sops/age/keys.txt`)
> in 1Password / Bitwarden / encrypted offline USB. Without a backup,
> every SOPS-encrypted secret becomes unrecoverable on the first disk crash.

### In any repo

```sh
cp ~/.local/share/dotfiles/examples/sops.yaml .sops.yaml
$EDITOR .sops.yaml          # replace age1XXX… with your public key
sops secrets.enc.yaml       # transparent edit (auto encrypt/decrypt)
```

`SOPS_AGE_KEY_FILE` is exported by `home/dot_config/zsh/env.zsh` —
SOPS and every consumer (Helm secrets, Argo CD, etc.) picks it up
without explicit config.

### Recipient rotation

```sh
$EDITOR .sops.yaml             # add/remove a public key
sops updatekeys secrets.enc.yaml
```

---

## Maintenance

### `dotfiles-update` — full pass

In this order:

1. System package upgrade (`pacman -Syu` / `apt upgrade` / `scoop update *`)
2. `chezmoi update --apply` (pull repo + apply)
3. `mise upgrade` (toolchain runtimes)
4. `nvim --headless +"Lazy! sync" +qa` (LazyVim plugins)
5. `nvim --headless +MasonUpdate +qa` (LSP / formatters / linters)
6. `bun update -g @oh-my-pi/pi-coding-agent` (omp, if bun present)
7. `claude update` (if supported by the installed version)
8. `zinit self-update && zinit update --all`

### Diagnostics

```sh
dotfiles-doctor       # checks PATH binaries, nvim startup, chezmoi state
chezmoi doctor        # native chezmoi diagnostic
chezmoi state get-bucket --bucket=scriptState   # run_onchange_* hashes
chezmoi diff          # diff between source and $HOME — should be empty
```

---

## Architecture

### Data structure

```
home/.chezmoidata.toml          # shared source of truth
├── editors_available           # catalogue (key → label)
├── tools_available             # catalogue (key → label)
├── packages.<tool>.<os>        # per-OS package matrix (vanilla PM)
├── mise_plugins.<tool>         # mise fallback
└── vscode_extensions           # list for run_onchange_20

~/.config/chezmoi/chezmoi.toml  # per-machine, written by tui.sh
└── [data]
    ├── name, email, profile, proxy_*
    ├── editors = [...]         # user selections
    └── tools = [...]            # user selections
```

`tui.sh` loads the catalogues dynamically from `.chezmoidata.toml` via
a minimal awk parser — adding a tool only requires editing **one** file
(`.chezmoidata.toml`).

### Chezmoi hooks

All under `home/.chezmoiscripts/`, executed in lexical order:

| Hook | Role |
|---|---|
| `run_onchange_10-install-packages.sh.tmpl` | Package install (PM → mise → warn) |
| `run_onchange_20-install-vscode-extensions.sh.tmpl` | VSCode extensions (`code --install-extension`) |
| `run_onchange_30-cheatsheet.sh.tmpl` | (planned) Desktop cheatsheet generation |

Each hook embeds a `# data-hash: …` comment at the top, hashing the
relevant data — when it changes, the hash changes and chezmoi replays
the hook.

### File gating

`home/.chezmoiignore` (templated) dynamically excludes:

- On Linux: all of `home/AppData/`.
- On Windows: `home/dot_config/Code/`, `home/dot_config/zed/`.
- If `code` isn't in `.editors`: both VSCode configs.
- If `zed` isn't in `.editors`: the Zed config.
- If `nvim` isn't in `.editors`: `home/dot_config/nvim/`.

Result: a user who picks Neovim only has zero VSCode/Zed footprint in
their `$HOME`.

---

## Quality — multi-OS CI

`.github/workflows/ci.yml` (cheap jobs, on every PR):

| Job | Target |
|---|---|
| `shell` | shellcheck + shfmt on every `.sh` (install/bootstrap/lib/tui/dotfiles-*) |
| `powershell` | parse `[scriptblock]::Create` + PSScriptAnalyzer on every `.ps1` |
| `lua` | luacheck on `home/dot_config/{nvim,wezterm}/lua` |
| `actionlint` | self-lint of the workflows |
| `nvim` | headless `Lazy! sync` + smoke test (empty stderr) |
| `chezmoi` | profile matrix: `chezmoi apply --dry-run` + validates settings.json / `.gitconfig` |
| `apply-idempotence` | profile × editors × tools matrix (6 entries): apply 2× under `DOTFILES_DRY_RUN=1`, `chezmoi diff` empty after the 1st, zero `^(create\|update\|modify\|run )` lines on the 2nd |

`.github/workflows/bootstrap-windows-e2e.yml` (manual + push on the
Windows script): full install on a clean Windows runner as a non-admin
user (mirrors the Safran corporate target).

---

## Uninstall

Safe-mode — peels off the dotfiles layer without touching shared system
packages:

```sh
./scripts/uninstall-arch.sh           # Arch
./scripts/uninstall-ubuntu.sh         # Ubuntu / Debian
.\scripts\uninstall-windows.ps1       # Windows
.\scripts\uninstall-windows.ps1 -Full # Windows + nuke Scoop entirely
```

Linux: the scripts intentionally do **not** uninstall pacman/apt
packages (they're shared with the rest of the system). For a full wipe,
run `pacman -Rns …` or `apt remove …` manually.

---

## Repo layout

```
dotfiles/
├── home/                                 chezmoi source state (target = $HOME)
│   ├── .chezmoidata.toml                 catalogue + package matrix + mise_plugins
│   ├── .chezmoiignore                    OS gating + opt-in editors (templated)
│   ├── .chezmoi.toml.tmpl                fallback prompts when no TUI ran
│   ├── .chezmoiscripts/                  run_onchange_* hooks
│   ├── .chezmoitemplates/                partials (vscode-settings.json…)
│   ├── dot_config/                       → ~/.config/
│   │   ├── zsh/                          modular zsh (env / path / plugins…)
│   │   ├── nvim/                         LazyVim
│   │   ├── Code/User/settings.json.tmpl  VSCode (Linux/macOS)
│   │   ├── zed/settings.json.tmpl
│   │   ├── starship.toml
│   │   ├── lazygit/
│   │   ├── tmux/
│   │   ├── wezterm/
│   │   └── ripgrep/
│   ├── AppData/Roaming/Code/User/        VSCode (Windows)
│   ├── Desktop/CHEATSHEET.md.tmpl        conditional cheatsheet
│   ├── dot_claude/                       → ~/.claude/ (settings, agents)
│   ├── dot_local/
│   │   ├── bin/                          dotfiles-update / doctor / config / keygen-age
│   │   └── share/dotfiles/examples/      ready-to-copy .sops.yaml
│   └── dot_gitconfig.tmpl                templated Git identity
├── scripts/
│   ├── install.sh / install.ps1          Plug & Play entry point (per OS)
│   ├── bootstrap-arch.sh                 Arch prerequisites + launches the TUI
│   ├── bootstrap-ubuntu.sh               same for Ubuntu / Debian
│   ├── bootstrap-windows.ps1             same for Windows (Scoop + MSYS2)
│   ├── uninstall-{arch,ubuntu,windows}*  safe uninstall
│   └── common/
│       ├── lib.sh                        helpers: log::*, has_cmd, pkg::*, prompt::*, gum::ensure
│       └── tui.sh                        gum TUI + chezmoi.toml writer
├── docs/                                 ADRs, troubleshooting, long-form install
├── .github/workflows/                    ci.yml + bootstrap-windows-e2e.yml
├── .gitattributes                        forces eol=lf on shell scripts
└── README.md
```

---

## Detailed documentation

- [`docs/install.md`](./docs/install.md) — what the bootstrap installs, manual steps, verification
- [`docs/cheatsheet.md`](./docs/cheatsheet.md) — WezTerm / Neovim / Lazygit / zsh keybindings and aliases
- [`docs/troubleshooting.md`](./docs/troubleshooting.md) — clipboard, MSYS2 quirks, chezmoi prompt gotchas
- [`docs/decisions.md`](./docs/decisions.md) — architecture decision records
- [`docs/migration-to-ghostty.md`](./docs/migration-to-ghostty.md) — planned WezTerm → Ghostty port
- [`docs/plan-history.md`](./docs/plan-history.md) — historical implementation plan

---

## Contributing / forking

The repo is designed to be forked. To adapt it to your identity:

1. Fork on GitHub.
2. Replace `tony/dotfiles` with `<you>/dotfiles` in `scripts/install.sh`,
   `scripts/install.ps1`, and every `bootstrap-*`.
3. Edit `home/.chezmoi.toml.tmpl` to rename the profiles (`safran` is the
   author's corporate profile — you'll likely want `work` or `corp`).
4. Tune `home/.chezmoidata.toml` (catalogue, package matrix,
   `vscode_extensions`).
5. CI runs automatically on your fork — make sure
   `apply-idempotence` stays green before relying on it.

License: [MIT](./LICENSE).
