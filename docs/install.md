# Install — ce qu'il faut pour que tout fonctionne

Le bootstrap (`scripts/bootstrap-*.sh`) couvre la majorité de l'installation.
Ce document explique ce qu'il installe, ce qui est manuel, et comment vérifier
que tout est en ordre.

---

## TL;DR — première machine

```sh
# Linux
./scripts/bootstrap-linux.sh

# macOS
./scripts/bootstrap-mac.sh

# Windows (PowerShell non-admin)
.\scripts\bootstrap-windows.ps1
```

Puis, dans un nouveau terminal :

```sh
nvim          # déclenche lazy.nvim + Mason au premier lancement
claude auth login
```

---

## Ce que le bootstrap installe automatiquement

### Outils systèmes (via le gestionnaire de paquets)

| Outil | Arch (`pacman`) | Debian/Ubuntu (`apt`) | macOS (`brew`) |
|-------|:-:|:-:|:-:|
| `zsh` | ✓ | ✓ | ✓ |
| `git` | ✓ | ✓ | ✓ |
| `neovim` | ✓ | ✓ | ✓ |
| `chezmoi` | ✓ | via curl | via curl |
| `fzf` | ✓ | ✓ | ✓ |
| `zoxide` | ✓ | ✓ | ✓ |
| `ripgrep` | ✓ | ✓ | ✓ |
| `fd` | ✓ | `fd-find` (symlinké) | ✓ |
| `bat` | ✓ | ✓ | ✓ |
| `eza` | ✓ | ⚠ absent (voir ci-dessous) | ✓ |
| `starship` | ✓ | via curl | ✓ |
| `atuin` | ✓ | via curl | ✓ |
| `mise` | ✓ | via curl | ✓ |
| `lazygit` | ✓ | ⚠ absent (voir ci-dessous) | ✓ |
| `git-delta` | ✓ | ⚠ absent (voir ci-dessous) | ✓ |
| `gh` | ✓ | — | ✓ |
| `tmux` | ✓ | ✓ | ✓ |
| `jq` / `yq` | ✓ | `jq` seulement | ✓ |
| `ttf-jetbrains-mono-nerd` | ✓ | — | ✓ (cask) |

### Outils auto-bootstrappés (pas de commande système requise)

| Outil | Mécanisme |
|-------|-----------|
| `zinit` | cloné par `plugins.zsh` au premier lancement zsh |
| `lazy.nvim` + LazyVim | cloné par `lua/config/lazy.lua` au premier `nvim` |
| LSP, formatters, linters | installés par Mason (`:MasonInstall` ou auto au premier `nvim`) |

---

## Installations manuelles sur Debian/Ubuntu

Le dépôt `apt` ne propose pas encore `eza`, `lazygit`, ni `git-delta` de façon
fiable. À installer à la main :

### eza
```sh
# Via cargo (nécessite rust)
cargo install eza

# Ou via release GitHub
EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | jq -r .tag_name)
curl -Lo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
tar -xf /tmp/eza.tar.gz -C ~/.local/bin eza
```

### git-delta
```sh
DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | jq -r .tag_name)
curl -Lo /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
sudo dpkg -i /tmp/delta.deb
```

### lazygit
```sh
LG_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name | sed 's/v//')
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
tar -xf /tmp/lazygit.tar.gz -C ~/.local/bin lazygit
```

---

## Étapes post-bootstrap (toutes plateformes)

Ces étapes ne peuvent pas être automatisées — elles nécessitent une interaction.

### 1. Police Nerd Font dans WezTerm

La config utilise `JetBrainsMono Nerd Font`. Si les icônes s'affichent comme
des carrés `[?]`, la police n'est pas installée ou pas sélectionnée.

- **Linux** : `fc-list | grep -i jetbrains` — si vide, installer
  `ttf-jetbrains-mono-nerd` (Arch) ou télécharger depuis nerdfonts.com.
- **macOS** : `brew install --cask font-jetbrains-mono-nerd-font`
- **Windows** : le bootstrap tente `scoop install JetBrains-Mono-NF`

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

### 3. Claude CLI

```sh
claude auth login
```

L'alias `cc` (zsh) pointe sur ce binaire — il doit être dans le PATH avant.
Le bootstrap installe Claude Code via l'installeur officiel natif
(`curl -fsSL https://claude.ai/install.sh | bash` — ou `install.ps1` sous
Windows). La méthode `npm install -g @anthropic-ai/claude-code` est
aujourd'hui legacy.

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

## Vérification rapide

```sh
# Outils shell
for cmd in zsh git nvim chezmoi fzf zoxide rg fd bat eza starship atuin mise lazygit delta; do
    command -v "$cmd" &>/dev/null && echo "✓ $cmd" || echo "✗ $cmd MANQUANT"
done

# Neovim
nvim --headless -c "checkhealth" -c "qa"  # ou lancer :checkhealth dans nvim

# Police
fc-list | grep -i jetbrains  # Linux seulement
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
| Nerd Font | icônes starship/lazygit/nvim cassées |
