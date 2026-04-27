# dotfiles

> KISS, multi-OS dotfiles managed by [chezmoi](https://www.chezmoi.io/).
> Three targets: **Windows native (Scoop)**, **WSL2 Ubuntu/Debian**,
> **Arch Linux**. One install command per OS, no menu, no profile.

[![CI](https://github.com/tony/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/tony/dotfiles/actions/workflows/ci.yml)

---

## Quick start

### Linux (Ubuntu / Debian / Arch — incl. WSL2)

```sh
curl -fsSL https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.sh | bash
```

### Windows (PowerShell, no admin)

```powershell
irm https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.ps1 | iex
```

Both scripts ask three questions: HTTP/HTTPS proxy, full name, email.
If `$HTTP_PROXY` is already exported, the proxy questions are skipped.

---

## Stack

| Layer            | Tool                                              |
| ---------------- | ------------------------------------------------- |
| Dotfile manager  | chezmoi                                           |
| Shell            | zsh (Linux), pwsh / PowerShell 7 (Windows native) |
| Prompt           | starship (cross-shell — same prompt everywhere)   |
| Terminal         | WezTerm                                           |
| Editor           | Neovim + LazyVim                                  |
| Git UI           | lazygit                                           |
| Git pager        | git-delta                                         |
| Smarter `cd`     | zoxide (`cd` is replaced)                         |
| `ls` replacement | eza                                               |
| Fuzzy finder     | fzf                                               |
| AI in terminal   | Claude Code, oh-my-pi (`omp`)                     |
| Package manager  | pacman / apt / Scoop                              |

### Shell parity

The pwsh profile (`Documents/PowerShell/Microsoft.PowerShell_profile.ps1`)
mirrors `~/.config/zsh/.zshrc`: same starship prompt, same zoxide-replaced
`cd`, same `ls`/`ll`/`lg` aliases, predictive history (PSReadLine ≈
zsh-autosuggestions). Open WezTerm on Linux or Windows: same UX.

The full list lives in `home/.chezmoidata.toml`.

---

## How it works

1. `scripts/install.{sh,ps1}` installs prereqs (`git`, `chezmoi`,
   `scoop` on Windows, `zsh` on Linux), prompts for proxy + identity,
   pre-writes `~/.config/chezmoi/chezmoi.toml`, then runs
   `chezmoi init --apply <repo>`.
2. `chezmoi apply` deploys `home/` → `$HOME` and runs
   `home/.chezmoiscripts/run_onchange_10-install-packages.sh.tmpl`,
   which installs the rest of the stack via the OS package manager
   (with upstream fallbacks on Ubuntu where apt is missing or stale).
3. `claude` and `omp` come from their own upstream installers
   (`https://claude.ai/install.sh`, `oh-my-pi`).

Re-running install or `chezmoi apply` is safe — every step is idempotent.

---

## User Space — local overrides

Never edit a tracked file to customise your environment. Drop your
personal stuff in these (untracked) files:

| Concern                            | File                                              |
| ---------------------------------- | ------------------------------------------------- |
| Personal zsh aliases / functions   | `~/.config/zsh/local.zsh`                         |
| Personal pwsh aliases / functions  | `$HOME\Documents\PowerShell\local.ps1`            |
| Git identity / signing key         | `~/.gitconfig.local`                              |
| Git identity for `~/work/*`        | `~/.gitconfig.work`                               |

---

## Maintenance

```sh
dotfiles-update             # apt/pacman/scoop upgrade + chezmoi update + LazyVim sync + claude/omp update
dotfiles-update --no-pkg    # skip system package upgrade (flaky proxy)
dotfiles-doctor             # health check: PATH, nvim, chezmoi
```

PowerShell variants: `dotfiles-update.ps1`, `dotfiles-doctor.ps1`.

---

## Repo layout

```
dotfiles/
├── home/                                source state (target = $HOME)
│   ├── .chezmoidata.toml                stack list per OS
│   ├── .chezmoi.toml.tmpl               fallback prompts
│   ├── .chezmoiignore                   per-OS gating
│   ├── .chezmoiscripts/                 run_onchange_* hooks
│   ├── dot_config/{zsh,nvim,wezterm,…}  ~/.config/... (Linux + WSL)
│   ├── Documents/PowerShell/            $PROFILE for pwsh / PS 5.1 (Windows)
│   ├── dot_claude/                      ~/.claude/
│   ├── dot_local/bin/                   dotfiles-update / dotfiles-doctor
│   └── dot_gitconfig.tmpl               ~/.gitconfig
├── scripts/
│   ├── install.sh / install.ps1         one-shot bootstrap per OS
│   └── uninstall.sh / uninstall-windows.ps1
├── .github/workflows/ci.yml             shellcheck + PSScriptAnalyzer + chezmoi apply
└── README.md
```

---

## Uninstall

```sh
./scripts/uninstall.sh                  # Linux
.\scripts\uninstall-windows.ps1         # Windows (apps only)
.\scripts\uninstall-windows.ps1 -Full   # Windows + nuke Scoop
```

Linux uninstall does **not** remove system packages (they're shared with
the rest of the system). `pacman -Rns …` / `apt remove …` if you want
that too.

---

License: [MIT](./LICENSE).
