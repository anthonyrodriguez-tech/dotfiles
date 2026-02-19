# dotfiles — tony@MateBook D14

## Matériel

| Composant | Détail |
|-----------|--------|
| Machine | Huawei MateBook D14 |
| RAM | 8 GB soudée (LPDDR4) |
| OS | Arch Linux |
| DE | XFCE |
| Terminal | Kitty |
| Shell | Nushell |

## Stack logicielle

| Outil | Rôle |
|-------|------|
| [kitty](https://sw.kovidgoyal.net/kitty/) | Terminal GPU-accelerated |
| [nushell](https://www.nushell.sh/) | Shell par défaut, données structurées |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` intelligent (remplace `cd`) |
| [stow](https://www.gnu.org/software/stow/) | Gestion des symlinks dotfiles |
| [JetBrains Mono Nerd Font](https://www.nerdfonts.com/) | Police terminal avec icônes |

## Structure

```
dotfiles/
├── kitty/
│   └── .config/kitty/
│       └── kitty.conf          # Font + thème Catppuccin Mocha
└── nushell/
    └── .config/nushell/
        ├── config.nu           # Settings, aliases
        ├── env.nu              # PATH
        └── zoxide.nu           # Généré par zoxide init nushell
```

## Déploiement (fresh install)

```bash
# 1. Installer les dépendances
sudo pacman -S stow nushell kitty zoxide git

# 2. Installer JetBrains Nerd Font
sudo pacman -S ttf-jetbrains-mono-nerd

# 3. Cloner et déployer
git clone <repo> ~/dotfiles
cd ~/dotfiles
stow kitty nushell
```

## Ajouter un nouveau programme

```bash
mkdir -p ~/dotfiles/monprog/.config/monprog
# copier la config dedans
cd ~/dotfiles
stow monprog
git add -A && git commit -m "add: monprog"
```

## Zoxide

```fish
z foo        # cd intelligent vers un dossier contenant "foo"
zi           # sélecteur interactif (nécessite fzf)
z -          # revenir au dossier précédent
```
