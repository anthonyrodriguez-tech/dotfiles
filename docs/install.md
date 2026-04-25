# Install — ce qu'il faut pour que tout fonctionne

Le bootstrap (`scripts/bootstrap-*.sh` ou `.ps1`) couvre la majorité de
l'installation. Ce document explique ce qu'il installe, ce qui est manuel,
et comment vérifier que tout est en ordre.

---

## TL;DR — première machine

```sh
# Arch Linux
./scripts/bootstrap-arch.sh

# Ubuntu / Debian
./scripts/bootstrap-ubuntu.sh

# Windows (PowerShell non-admin)
.\scripts\bootstrap-windows.ps1
```

Puis, dans un nouveau terminal :

```sh
nvim          # déclenche lazy.nvim + Mason au premier lancement
claude        # premier lancement → login navigateur
omp           # configurer les providers via /login
```

---

## Ce que le bootstrap installe automatiquement

### Outils systèmes (via le gestionnaire de paquets)

| Outil | Arch (`pacman`) | Debian/Ubuntu (`apt`) | Windows (`scoop`) |
|-------|:-:|:-:|:-:|
| `zsh` | ✓ | ✓ | via MSYS2 |
| `git` | ✓ | ✓ | ✓ |
| `neovim` | ✓ | ✓ | ✓ |
| `chezmoi` | ✓ | via curl | ✓ |
| `fzf` | ✓ | ✓ | ✓ |
| `zoxide` | ✓ | ✓ | ✓ |
| `ripgrep` | ✓ | ✓ | ✓ |
| `fd` | ✓ | `fd-find` (symlinké) | ✓ |
| `bat` | ✓ | `batcat` (symlinké) | ✓ |
| `eza` | ✓ | via release GitHub | ✓ |
| `starship` | ✓ | via curl | ✓ |
| `atuin` | ✓ | via curl | ✓ |
| `mise` | ✓ | via curl | ✓ |
| `lazygit` | ✓ | via release GitHub | ✓ |
| `git-delta` | ✓ | via release `.deb` | ✓ |
| `gh` | ✓ | via apt repo upstream | ✓ |
| `tmux` | ✓ | ✓ | — (WezTerm fait office de mux) |
| `jq` / `yq` | ✓ | `jq` seulement | ✓ |
| `ttf-jetbrains-mono-nerd` | ✓ | via release nerd-fonts | ✓ |

### Outils auto-bootstrappés (pas de commande système requise)

| Outil | Mécanisme |
|-------|-----------|
| `zinit` | cloné par `plugins.zsh` au premier lancement zsh |
| `lazy.nvim` + LazyVim | cloné par `lua/config/lazy.lua` au premier `nvim` |
| LSP, formatters, linters | installés par Mason (`:MasonInstall` ou auto au premier `nvim`) |

### Outils AI

| Outil | Linux | Windows | Note |
|-------|:-:|:-:|---|
| `claude` (Claude Code) | curl `claude.ai/install.sh` | irm `claude.ai/install.ps1` | Anthropic CLI officiel |
| `omp` (oh-my-pi) | curl `oh-my-pi/install.sh` | irm `oh-my-pi/install.ps1` | Fork de pi-mono, lit aussi `~/.claude/` |

---

## Étapes post-bootstrap (toutes plateformes)

Ces étapes ne peuvent pas être automatisées — elles nécessitent une interaction.

### 1. Police Nerd Font dans WezTerm

La config utilise `JetBrainsMono Nerd Font`. Si les icônes s'affichent comme
des carrés `[?]`, la police n'est pas installée ou pas sélectionnée.

- **Arch** : installée par `pacman` (`ttf-jetbrains-mono-nerd`)
- **Ubuntu/Debian** : installée par le bootstrap dans `~/.local/share/fonts/`
- **Windows** : `scoop install JetBrainsMono-NF` lancé par le bootstrap

Après installation : `fc-cache -fv` sur Linux, redémarrer WezTerm.

### 2. Premier lancement Neovim

```sh
nvim
```

`lazy.nvim` clone les plugins, puis Mason installe les LSP/formatters/linters
listés dans `lua/plugins/lsp.lua` et `lua/plugins/formatting.lua`.
Cela peut prendre 2–5 minutes. Vérifier avec `:checkhealth`.

**LSP installés automatiquement :** `omnisharp`, `ts_ls`, `terraformls`,
`dockerls`, `gopls`, `bashls`, `lua_ls`, `yamlls`.
**Formatters :** `csharpier`, `prettier`, `stylua`, `shfmt`.
**Linters :** `yamllint`, `actionlint`.
**Debugger :** `netcoredbg` (C#/.NET — ARM non supporté, voir troubleshooting).

### 3. Claude Code & oh-my-pi

```sh
claude          # première fois : login navigateur
omp             # première fois : /login pour configurer les providers
```

L'alias `cc` (zsh) pointe sur `claude`. Le bootstrap installe Claude Code via
l'installeur officiel natif (`curl -fsSL https://claude.ai/install.sh | bash`
— ou `install.ps1` sous Windows). La méthode `npm install -g @anthropic-ai/claude-code`
est aujourd'hui legacy.

`omp` lit nativement `~/.claude/commands/`, `~/.claude/agents/` et
`~/.claude/CLAUDE.md` — pas besoin de dupliquer la conf.

### 4. Shell par défaut

Le bootstrap tente `chsh -s $(which zsh)`. Si ça échoue (ex. machine sans
`sudo`) :

```sh
# Vérifier que zsh est dans /etc/shells
grep zsh /etc/shells

# Sinon, ajouter (nécessite root)
echo "$(which zsh)" | sudo tee -a /etc/shells
chsh -s "$(which zsh)"
```

---

## Maintenance au quotidien

```sh
dotfiles-update            # full pass (pkg + chezmoi + nvim + AI CLIs)
dotfiles-update --quick    # uniquement chezmoi update + nvim Lazy sync
dotfiles-update --no-pkg   # skip l'upgrade système (proxy capricieux)

dotfiles-doctor            # check santé : binaires, nvim, chezmoi
```

Voir [`README.md`](../README.md#maintenance) pour le détail des étapes.

---

## Vérification rapide

```sh
# Diagnostic intégré
dotfiles-doctor

# Manuel (si dotfiles-doctor n'est pas encore déployé)
for cmd in zsh git nvim chezmoi fzf zoxide rg fd bat eza starship atuin mise lazygit delta claude omp; do
    command -v "$cmd" &>/dev/null && echo "✓ $cmd" || echo "✗ $cmd MANQUANT"
done

# Neovim
nvim --headless -c "checkhealth" -c "qa"

# Police (Linux uniquement)
fc-list | grep -i jetbrains
```

---

## Tableau récapitulatif — criticité

| Outil | Sans lui… |
|-------|-----------|
| `zsh` | rien ne fonctionne |
| `git` | bootstrap impossible, zinit ne démarre pas |
| `nvim` | pas d'éditeur |
| `chezmoi` | dotfiles non déployés |
| `fzf` | `Ctrl-R`, `Ctrl-T`, `Alt-C`, `fkill`, `fbranch` cassés |
| `starship` | prompt basique par défaut |
| `eza` | `ll`/`la` non définis (fallback silencieux sur `ls`) |
| `bat` | `cat` reste `cat` |
| `delta` | diffs git sans coloration syntaxique |
| `lazygit` | `lg` introuvable |
| `atuin` | historique shell standard (moins puissant) |
| `zoxide` | `cd` standard (pas de smart jump) |
| `mise` | versions de runtime non gérées |
| `claude` / `omp` | pas d'agent IA dans le terminal |
| Nerd Font | icônes starship/lazygit/nvim cassées |
