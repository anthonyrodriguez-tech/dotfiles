# Install — détail

Le bootstrap (`scripts/install.sh` ou `install.ps1`) couvre la majorité de
l'installation. Ce document détaille ce qui est installé, ce qui est manuel,
et comment vérifier que tout est en ordre.

---

## TL;DR

```sh
# Linux (Ubuntu / Debian / Arch — incl. WSL2)
curl -fsSL https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.sh | bash

# Windows (PowerShell, no admin)
irm https://raw.githubusercontent.com/tony/dotfiles/main/scripts/install.ps1 | iex
```

Le script demande trois choses : proxy HTTP/HTTPS (skip si `$HTTP_PROXY`
déjà défini), nom complet, email. Puis tout s'enchaîne automatiquement.

Dans un nouveau terminal :

```sh
nvim          # déclenche lazy.nvim + Mason au premier lancement
claude        # premier lancement → login navigateur
omp           # configurer les providers via /login
```

---

## Ce que le bootstrap installe

| Outil                     | Arch (`pacman`) | Debian/Ubuntu (`apt`)  | Windows (`scoop`) |
| ------------------------- | :-------------: | :--------------------: | :---------------: |
| `zsh`                     | ✓               | ✓                      | — (pwsh à la place) |
| `pwsh` (PowerShell 7)     | —               | —                      | ✓                 |
| `git`                     | ✓               | ✓                      | ✓                 |
| `neovim`                  | ✓               | ✓                      | ✓                 |
| `chezmoi`                 | ✓               | via curl               | ✓                 |
| `wezterm`                 | ✓               | AppImage upstream      | ✓                 |
| `fzf`                     | ✓               | ✓                      | ✓                 |
| `zoxide`                  | ✓               | ✓                      | ✓                 |
| `ripgrep`                 | ✓               | ✓                      | ✓                 |
| `fd`                      | ✓               | `fd-find` (symlinké)   | ✓                 |
| `bat`                     | ✓               | `batcat` (symlinké)    | ✓                 |
| `eza`                     | ✓               | release GitHub         | ✓                 |
| `starship`                | ✓               | upstream installer     | ✓                 |
| `lazygit`                 | ✓               | release GitHub         | ✓                 |
| `git-delta`               | ✓               | release `.deb`         | ✓                 |
| `gh`                      | ✓               | apt repo upstream      | ✓                 |
| `jq` / `yq`               | ✓               | `jq` seulement         | ✓                 |
| JetBrains Mono Nerd Font  | ✓               | release nerd-fonts     | ✓                 |
| `zsh-autosuggestions`     | ✓               | ✓                      | —                 |
| `zsh-syntax-highlighting` | ✓               | ✓                      | —                 |

Outils auto-bootstrappés (gérés par leur propre installer) :

| Outil   | Mécanisme                                                        |
| ------- | ---------------------------------------------------------------- |
| LazyVim | `lazy.nvim` cloné par `init.lua` au premier `nvim`               |
| Mason   | LSP/formatters/linters installés au premier `nvim`               |
| claude  | `curl https://claude.ai/install.sh \| bash` (ou `install.ps1`)   |
| omp     | `curl https://raw.githubusercontent.com/can1357/oh-my-pi/...`    |

---

## Étapes post-bootstrap

### 1. Premier lancement Neovim

```sh
nvim
```

`lazy.nvim` clone les plugins, Mason installe les LSP/formatters/linters
listés dans `lua/plugins/lsp.lua` et `lua/plugins/formatting.lua`. Compte
2–5 minutes. Vérifier avec `:checkhealth`.

### 2. Claude Code & oh-my-pi

```sh
claude          # première fois : login navigateur
omp             # première fois : /login pour configurer les providers
```

L'alias `cc` (zsh) pointe sur `claude`. `omp` lit nativement
`~/.claude/commands/`, `~/.claude/agents/` et `~/.claude/CLAUDE.md`.

### 3. Shell par défaut

**Linux.** Le bootstrap tente `chsh -s $(which zsh)`. Si ça échoue :

```sh
grep zsh /etc/shells || echo "$(which zsh)" | sudo tee -a /etc/shells
chsh -s "$(which zsh)"
```

**Windows.** WezTerm lance directement `pwsh` (cherché dans
`~\scoop\apps\pwsh\current\` puis `Program Files\PowerShell\7\`). Le profil
PowerShell est déployé par chezmoi à `Documents\PowerShell\` (PS 7) et
`Documents\WindowsPowerShell\` (PS 5.1, qui dot-source le précédent —
un seul fichier à maintenir). Modules requis (`PSReadLine`, `PSFzf`)
installés par `install.ps1` au scope CurrentUser.

---

## Maintenance

```sh
dotfiles-update             # full: pkg upgrade + chezmoi + LazyVim + claude/omp
dotfiles-update --no-pkg    # skip system upgrade (proxy capricieux)
dotfiles-doctor             # health check
```

---

## Vérification

```sh
dotfiles-doctor
chezmoi doctor
nvim --headless +checkhealth +qa
fc-list | grep -i jetbrains   # Linux : police Nerd Font présente
```
