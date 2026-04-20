# Plan d'implémentation — dotfiles portables (Anthony)

> Document de référence pour Claude Code. Chaque phase est une unité de commit.
> Ne passe pas à la phase suivante sans validation explicite.

## Stack cible

| Couche | Choix | Motif |
|---|---|---|
| Gestion dotfiles | **chezmoi** | Templating multi-machines (perso/Safran/Genève/homelab), cross-OS natif |
| Shell | **zsh** (partout) | POSIX-compat, ubiquité corporate, écosystème mature |
| Terminal | **WezTerm** (maintenant) → **Ghostty** (plus tard) | WezTerm fonctionne nativement sur Windows sans WSL2 ; migration prévue |
| Multiplexer | Aucun sur Safran (WezTerm fait le job) ; **tmux** ailleurs | Pas de tmux natif Windows sans WSL2 |
| Prompt | **Starship** | Cross-shell, léger, modules K8s/AWS/Azure/Terraform |
| Éditeur | **Neovim + LazyVim** | Distro pré-configurée, customisable proprement |
| Git UI | **Lazygit** | Rapide, keyboard-driven |
| IA terminal | **Claude Code** | Config `~/.claude/` géré par chezmoi |
| Package mgr | brew (mac), apt/dnf/pacman (linux), **Scoop** (windows user-level) | Pas d'admin requis sur Safran |
| Secrets | Aucun pour l'instant (templating pur) | À rajouter plus tard (age) non-breaking |

## Philosophie

1. **Un seul repo**, une seule source de vérité. Forké/cloné sur chaque machine.
2. **chezmoi** fait le templating par profil (`personal`, `safran`, `geneva`, `homelab`).
3. **Zsh identique partout** : macOS / Linux / MSYS2 sur Windows.
4. **WezTerm keybindings = mimétique tmux** (`leader Ctrl-a`, `|`, `-`) pour migration sans douleur.
5. **Bootstrap idempotent** : relancer ne casse rien.
6. **Overrides locaux non trackés** : `~/.config/zsh/local.zsh`, `~/.gitconfig.local`.

---

## Structure cible du repo

```
dotfiles/
├── README.md
├── PLAN.md                                 ← ce fichier
├── LICENSE
│
├── home/                                   ← racine source chezmoi
│   ├── .chezmoi.toml.tmpl                  ← prompts init (email, profile…)
│   ├── .chezmoiignore
│   ├── .chezmoiroot                        ← (optionnel) si on sépare la racine
│   │
│   ├── dot_zshenv                          → ~/.zshenv (définit ZDOTDIR)
│   │
│   ├── dot_config/
│   │   ├── zsh/
│   │   │   ├── dot_zshrc                   → ~/.config/zsh/.zshrc (entry point)
│   │   │   ├── path.zsh
│   │   │   ├── env.zsh
│   │   │   ├── history.zsh
│   │   │   ├── options.zsh
│   │   │   ├── keybinds.zsh
│   │   │   ├── completion.zsh
│   │   │   ├── plugins.zsh                 (zinit bootstrap + plugins)
│   │   │   ├── aliases.zsh
│   │   │   ├── functions.zsh
│   │   │   └── integrations.zsh            (starship, zoxide, fzf, direnv, mise)
│   │   │
│   │   ├── wezterm/
│   │   │   ├── wezterm.lua                 (entry point)
│   │   │   ├── keybindings.lua             (leader Ctrl-a, |, -, h/j/k/l)
│   │   │   ├── appearance.lua              (fonts, catppuccin, tabs)
│   │   │   └── platform.lua                (branches macOS/Linux/Windows)
│   │   │
│   │   ├── starship.toml
│   │   │
│   │   ├── nvim/                           (LazyVim + overlay)
│   │   │   ├── init.lua
│   │   │   ├── lua/config/
│   │   │   │   ├── lazy.lua
│   │   │   │   ├── options.lua
│   │   │   │   ├── keymaps.lua
│   │   │   │   └── autocmds.lua
│   │   │   └── lua/plugins/
│   │   │       ├── colorscheme.lua
│   │   │       ├── lsp.lua                 (omnisharp/roslyn, tsserver, terraformls, gopls, yamlls)
│   │   │       ├── dap.lua                 (netcoredbg pour .NET)
│   │   │       ├── formatting.lua          (conform.nvim : csharpier, prettier, stylua)
│   │   │       ├── telescope.lua
│   │   │       ├── ui.lua                  (lualine, bufferline, noice)
│   │   │       └── extras.lua              (oil, trouble, which-key overrides)
│   │   │
│   │   ├── lazygit/
│   │   │   └── config.yml
│   │   │
│   │   ├── ripgrep/
│   │   │   └── ripgreprc
│   │   │
│   │   └── tmux/                           (uniquement utilisé hors Windows)
│   │       └── tmux.conf
│   │
│   ├── dot_claude/                         → ~/.claude/
│   │   ├── settings.json.tmpl              (profile-aware)
│   │   ├── CLAUDE.md                       (préférences globales)
│   │   ├── agents/
│   │   │   └── terraform-reviewer.md
│   │   └── commands/
│   │       └── review-pr.md
│   │
│   ├── dot_gitconfig.tmpl                  → ~/.gitconfig (templated avec .email/.name)
│   ├── dot_gitignore_global
│   │
│   └── dot_local/
│       └── bin/
│           ├── executable_mkcd
│           └── executable_extract          (archive extractor universel)
│
├── scripts/                                ← non géré par chezmoi (ignoré)
│   ├── bootstrap-mac.sh
│   ├── bootstrap-linux.sh
│   ├── bootstrap-windows.ps1               (Scoop + MSYS2 + zsh + tout le reste)
│   └── common/
│       └── install-nerd-font.sh
│
└── docs/
    ├── decisions.md                        (ADRs : pourquoi zsh, pourquoi WezTerm…)
    ├── migration-to-ghostty.md             (plan quand Anthony bascule)
    ├── troubleshooting.md
    └── cheatsheet.md                       (keybindings WezTerm, zsh, nvim, lazygit)
```

---

## Phases (ordre strict)

### Phase 0 — Squelette du repo (30 min)
**Objectif** : repo Git initialisé, structure de dossiers créée, README de base.

- `git init`, `.gitignore` (exclut `scripts/` des outputs chezmoi, `*.swp`, `.DS_Store`)
- Créer tous les dossiers de l'arbre ci-dessus (vides avec `.gitkeep` si besoin)
- `README.md` avec : titre, badges (placeholder), TOC, sections "Install", "Update", "Structure"
- Installer chezmoi localement pour valider : `chezmoi --version`
- `chezmoi init --source=$(pwd)/home` depuis le repo, valider qu'il détecte bien la structure

**Deliverable** : `git log` montre un commit `chore: initialize repo structure`.

---

### Phase 1 — chezmoi config (20 min)
**Objectif** : templating par profil fonctionnel.

- `home/.chezmoi.toml.tmpl` : prompts pour `email`, `name`, `profile` (choix : personal/safran/geneva/homelab)
- `home/.chezmoiignore` : exclure `README.md`, `scripts/`, `docs/`, `LICENSE`
- Tester le flow : `chezmoi init --source=. --apply=false` puis `chezmoi diff`
- Documenter la variable `.profile` dans `docs/decisions.md` (comment l'utiliser dans les templates)

**Deliverable** : commit `feat: chezmoi templating with per-machine profiles`.

---

### Phase 2 — Zsh universel (2 h)
**Objectif** : zsh config modulaire qui tourne identiquement sur macOS/Linux/MSYS2.

Fichiers à créer (voir arbre) :
- `dot_zshenv` (définit `ZDOTDIR=$XDG_CONFIG_HOME/zsh`)
- `dot_config/zsh/dot_zshrc` (entry point qui source les modules)
- `path.zsh` : PATH ordonné, détection OS (`Darwin`/`Linux`/`MINGW*|MSYS*` → variable `$DOTFILES_OS`), Homebrew eval si mac, `mise activate` si présent
- `env.zsh` : `EDITOR=nvim`, `PAGER=less`, `MANPAGER='nvim +Man!'`, `LESS`, `FZF_DEFAULT_COMMAND` avec fd, `BAT_THEME`, `RIPGREP_CONFIG_PATH`, locale
- `history.zsh` : `HISTFILE=$XDG_STATE_HOME/zsh/history`, `HISTSIZE=50000`, `SAVEHIST=50000`, options (`HIST_IGNORE_DUPS`, `HIST_VERIFY`, `SHARE_HISTORY`, `EXTENDED_HISTORY`)
- `options.zsh` : `setopt AUTO_CD`, `GLOB_DOTS`, `INTERACTIVE_COMMENTS`, `NO_BEEP`, `PROMPT_SUBST`
- `keybinds.zsh` : emacs par défaut (`bindkey -e`), recherche historique par préfixe (up/down), `Ctrl-R` via fzf
- `completion.zsh` : `compinit` avec cache XDG, menu-select, case-insensitive, couleurs
- `plugins.zsh` : bootstrap **zinit** (auto-install si absent) + plugins :
  - `zsh-users/zsh-autosuggestions`
  - `zsh-users/zsh-syntax-highlighting` (toujours en dernier)
  - `Aloxaf/fzf-tab` (remplace le menu compinit par fzf)
  - `zsh-users/zsh-completions`
- `aliases.zsh` : git (g/gs/gd/gc/gp/gl…), nvim (v/vi/vim), tmux (t/ta/tn — wrap en check `command -v tmux`), docker/k/tf/cc=claude, eza si dispo, bat si dispo
- `functions.zsh` : `mkcd`, `fkill` (fzf process killer), `fbranch` (fzf git switch), `extract` (tar/zip/gz/bz2)
- `integrations.zsh` : `starship init zsh`, `zoxide init zsh --cmd cd`, `fzf` keybindings, `direnv hook zsh`, `atuin init zsh` (optionnel)

**Points de vigilance** :
- Sur MSYS2 (Windows), certains paquets n'existent pas (eza, zoxide, bat). Les commandes `command -v` doivent **toujours** précéder les aliases modernes.
- `compinit` est lent — utiliser la pattern "cache daily" (`zcompdump` par jour).
- `zinit` doit s'installer silencieusement au premier run sans bloquer le shell.

**Deliverable** : commit `feat(zsh): modular portable config with zinit plugins`.

---

### Phase 3 — WezTerm (1 h 30)
**Objectif** : terminal + multiplexing, keybindings tmux-like.

- `wezterm.lua` (entry point) : require les sous-modules, retourne la config finale
- `appearance.lua` : font (JetBrainsMono Nerd Font, 13pt), scheme (Catppuccin Mocha), tabs en haut, window padding, cursor beam, opacité si goût
- `platform.lua` : détection `wezterm.target_triple` → adapter `default_prog` (`zsh` sur mac/linux, **MSYS2 zsh** sur Windows : `C:\\tools\\msys64\\usr\\bin\\zsh.exe -li` avec env `MSYSTEM=MSYS` et `CHERE_INVOKING=1`), `freetype_load_target` différent selon OS
- `keybindings.lua` :
  - **Leader = `CTRL-a`** (timeout 1000 ms) pour mimer tmux
  - `leader |` → split horizontal (CTRL+ALT+PIPE = même touche physique)
  - `leader -` → split vertical
  - `leader h/j/k/l` → navigation panes (CursorMotion Left/Down/Up/Right)
  - `leader z` → toggle zoom pane
  - `leader c` → new tab
  - `leader n`/`p` → next/prev tab
  - `leader 0-9` → tab par index
  - `leader x` → close pane (avec confirm)
  - `leader [` → entrer copy mode
  - `leader r` → reload config (SHIFT+R)
  - `leader s` → workspace switcher (fuzzy)
  - Garder `CTRL+SHIFT+C/V` pour copy/paste classique
- Activer `use_fancy_tab_bar = false` pour un rendu minimal cohérent cross-OS
- Tester la config avec `wezterm --config-file ./wezterm.lua start`

**Deliverable** : commit `feat(wezterm): tmux-like keybindings, catppuccin theme, cross-OS shell detection`.

---

### Phase 4 — Starship (30 min)
**Objectif** : prompt informatif pour contexte DevOps.

`starship.toml` avec modules activés :
- `directory` (truncation intelligente, home_symbol `~`)
- `git_branch`, `git_status` (symboles minimaux)
- `cmd_duration` (threshold 2000ms)
- `kubernetes` (activé, symbole `⎈`, format court `$context($namespace)`)
- `aws` (profile + region si `AWS_PROFILE` set)
- `azure` (subscription si connecté)
- `terraform` (workspace)
- `dotnet` (version si `.csproj`/`.sln` dans le CWD)
- `nodejs`, `python`, `golang`, `rust` (contextuels)
- `character` : `❯` vert / rouge
- Format à 2 lignes (première : contextes, deuxième : caractère de prompt)
- Palette Catppuccin Mocha pour cohérence

**Deliverable** : commit `feat(starship): devops-oriented prompt with k8s/aws/azure/terraform`.

---

### Phase 5 — Neovim + LazyVim (3 h)
**Objectif** : LazyVim avec overlay custom orienté .NET / DevOps.

**Structure** :
- `init.lua` : charge `config.lazy`
- `lua/config/lazy.lua` : bootstrap lazy.nvim + LazyVim import + plugins custom
- `lua/config/options.lua` : override `relativenumber`, `scrolloff=8`, `clipboard=unnamedplus`, etc.
- `lua/config/keymaps.lua` : mappings perso (conserver LazyVim par défaut)
- `lua/config/autocmds.lua` : `TextYankPost` highlight, trim trailing whitespace

**Plugins overlay** (`lua/plugins/`) :
- `colorscheme.lua` : catppuccin-mocha via `LazyVim.config` (forcer le thème)
- `lsp.lua` : config mason-lspconfig pour `omnisharp`/`roslyn_ls`, `tsserver`, `terraformls`, `gopls`, `yamlls` (avec schemas Kubernetes + GitLab CI + GitHub Actions), `bashls`, `lua_ls`, `dockerls`
- `dap.lua` : `nvim-dap` + `nvim-dap-ui` + adapter `netcoredbg` pour debug .NET (important pour Safran)
- `formatting.lua` : conform.nvim avec `csharpier` (.cs), `prettier` (ts/tsx/json/md), `stylua` (lua), `terraform fmt`, `shfmt`
- `telescope.lua` : extensions `fzf-native`, `file_browser`, keymaps étendus
- `ui.lua` : désactiver `dashboard` par défaut → mettre `snacks.dashboard` avec quick actions (recent, projects, config)
- `extras.lua` : `oil.nvim` (file manager), `trouble.nvim` override, `which-key` groupes custom

**Activation LazyVim extras** (via `lazyvim.json`) :
- `extras.lang.typescript`
- `extras.lang.terraform`
- `extras.lang.docker`
- `extras.lang.yaml`
- `extras.lang.rust` (pour plus tard)
- `extras.coding.yanky`
- `extras.editor.harpoon2`
- `extras.dap.core`

**Points de vigilance** :
- Sur MSYS2, certains LSPs ne s'installent pas bien via mason → documenter workaround.
- `clipboard=unnamedplus` nécessite `xclip`/`wl-clipboard` (Linux) ou `win32yank` (MSYS2).

**Deliverable** : commit `feat(nvim): LazyVim base + .NET/DevOps overlay`.

---

### Phase 6 — Lazygit (30 min)
- `config.yml` : theme Catppuccin Mocha, delta comme pager, keybindings perso (optionnel)
- Vérifier intégration avec le `~/.gitconfig` (notamment `[core] pager = delta`)
- Alias `lg` déjà dans `aliases.zsh`

**Deliverable** : commit `feat(lazygit): catppuccin theme + delta pager integration`.

---

### Phase 7 — Claude Code (1 h)
- `settings.json.tmpl` : templating chezmoi avec `{{ if eq .profile "safran" }}` pour :
  - `env`: vars proxy éventuelles
  - `permissions`: plus restrictif en pro (pas d'accès internet-wide, par exemple)
- `CLAUDE.md` global : préférences (français, concision, pas d'emoji sauf demande, conventions commit, style code)
- `agents/terraform-reviewer.md` : agent spécialisé revue Terraform (pertinent Safran + Genève)
- `commands/review-pr.md` : slash command `/review-pr` qui lance une revue complète (diff, lint, security)
- Documenter dans le README comment s'authentifier après install (`claude auth login`)

**Deliverable** : commit `feat(claude): templated settings + DevOps-oriented agents and commands`.

---

### Phase 8 — Git config (30 min)
- `dot_gitconfig.tmpl` avec :
  - `[user] name = {{ .name }}`, `email = {{ .email }}` (templated)
  - `[core] pager = delta`, `editor = nvim`, `autocrlf = input` (sauf Windows natif → `true`)
  - `[init] defaultBranch = main`
  - `[pull] rebase = true`, `[push] autoSetupRemote = true`
  - `[delta]` theme + line-numbers + navigate
  - `[include] path = ~/.gitconfig.local` (override non tracké, pour email pro Safran si besoin)
  - `[alias]` : sync, undo, lg, cleanup, …
- `dot_gitignore_global` : éditeurs, OS, IDE, `.env`, `.direnv/`
- `[includeIf "gitdir:~/work/"]` pour utiliser automatiquement l'email pro dans `~/work/`

**Deliverable** : commit `feat(git): templated identity + delta + conditional includes`.

---

### Phase 9 — Scripts bootstrap (3 h)
**Trois scripts parallèles, pas croisés** :

**`scripts/bootstrap-mac.sh`** (bash) :
- Install Xcode CLI tools si absent
- Install Homebrew si absent
- `brew bundle` depuis un `Brewfile` embarqué : chezmoi, zsh, wezterm-cask, neovim, lazygit, starship, tmux, ripgrep, fd, fzf, bat, eza, zoxide, git-delta, jq, yq, node, mise, JetBrainsMono Nerd Font cask
- `chezmoi init --apply https://github.com/<user>/dotfiles.git`
- `chsh -s $(brew --prefix)/bin/zsh`
- Install Claude Code : `npm install -g @anthropic-ai/claude-code`

**`scripts/bootstrap-linux.sh`** (bash, avec détection apt/dnf/pacman) :
- Mêmes outils, adaptés au gestionnaire
- Fallback pour paquets manquants (eza, zoxide, starship via installer upstream)
- Nerd Font via `getnf` ou install manuel
- `chezmoi init --apply ...`
- Changer le shell : `chsh -s $(which zsh)`

**`scripts/bootstrap-windows.ps1`** (PowerShell, le plus complexe) :
- Check version Windows (>= 10 build 18362 pour wt/WezTerm propre)
- Install **Scoop** si absent :
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  irm get.scoop.sh | iex
  ```
- `scoop bucket add extras nerd-fonts`
- `scoop install git chezmoi wezterm neovim lazygit starship ripgrep fd fzf bat jq yq delta zoxide msys2 nodejs`
- `scoop install JetBrainsMono-NF`
- **Setup MSYS2 + zsh** :
  - Lancer `msys2_shell.cmd` une fois pour init
  - Depuis MSYS2 : `pacman -Syu --noconfirm` (puis re-run, normal)
  - `pacman -S --noconfirm zsh git curl wget stow`
  - Copier un loader `~/.bashrc` qui exec zsh si interactif (pour les gens qui tombent sur bash par erreur)
- Install `win32yank` pour clipboard Neovim
- `chezmoi init --apply https://github.com/<user>/dotfiles.git`
- Documenter dans le README comment configurer WezTerm pour lancer **MSYS2 zsh** par défaut (lien vers `platform.lua`)

**Points de vigilance Windows** :
- Proxy Safran : documenter `scoop config proxy <host>:<port>` et `git config --global http.proxy`
- Pas d'admin : tout doit tenir en user-level (Scoop = ✓, MSYS2 via Scoop = ✓)
- `chsh` n'existe pas — le shell par défaut WezTerm se configure dans `wezterm.lua`

**Deliverable** : 3 commits séparés, un par plateforme.

---

### Phase 10 — Docs (1 h)
- `README.md` final : refait proprement avec install en 1 commande par OS, screenshots (placeholders), section troubleshooting
- `docs/decisions.md` : ADRs pour zsh vs fish, chezmoi vs stow, WezTerm vs Kitty, Scoop vs Winget
- `docs/migration-to-ghostty.md` : plan de bascule (remplacer `wezterm/` par `ghostty/`, ajouter tmux.conf, keybindings quasi-identiques si leader tmux déjà utilisé)
- `docs/cheatsheet.md` : WezTerm, zsh aliases, nvim LazyVim (principaux), lazygit
- `docs/troubleshooting.md` : erreurs fréquentes (font manquante, proxy, LSP qui rate sur MSYS2, clipboard…)

**Deliverable** : commit `docs: complete documentation and ADRs`.

---

### Phase 11 — Validation & polish (1 h)
- Tester `chezmoi diff` sur une machine propre (VM Linux si possible)
- Lancer `shellcheck` sur tous les `.sh`
- Lancer `PSScriptAnalyzer` sur le `.ps1`
- `luacheck` sur les fichiers Lua (Neovim + WezTerm)
- Vérifier que `chezmoi apply` est idempotent (re-run → aucun changement)
- Ajouter un CI GitHub Actions minimal : `shellcheck` + `luacheck` + `chezmoi verify`
- Tag v0.1.0

**Deliverable** : commit `chore: ci + linting + v0.1.0 tag`.

---

## Variables de template chezmoi utilisées

| Variable | Source | Exemple | Utilisée dans |
|---|---|---|---|
| `.email` | prompt init | `anthony@example.com` | `dot_gitconfig.tmpl` |
| `.name` | prompt init | `Anthony` | `dot_gitconfig.tmpl` |
| `.profile` | prompt init (choix) | `safran` | `dot_claude/settings.json.tmpl`, conditionnels divers |
| `.chezmoi.os` | auto | `linux` / `darwin` / `windows` | bootstrap conditionnel dans templates |
| `.chezmoi.hostname` | auto | `safran-laptop` | overrides par machine si besoin |

## Références externes à inclure dans le README

- chezmoi : https://www.chezmoi.io/
- LazyVim : https://www.lazyvim.org/
- WezTerm : https://wezfurlong.org/wezterm/
- Starship : https://starship.rs/
- Scoop : https://scoop.sh/
- Catppuccin : https://github.com/catppuccin

## Critères de "done"

Le repo est considéré fini quand :
1. `git clone` + lancer un des 3 scripts bootstrap fait tourner l'environnement complet sans intervention manuelle.
2. `chezmoi apply` est idempotent.
3. Les 3 OS (mac, linux, windows+MSYS2) passent les tests de base : zsh démarre, WezTerm s'ouvre, nvim charge LazyVim sans erreur, `g`/`gs`/`lg` fonctionnent, `claude --version` répond.
4. Le README permet à quelqu'un d'autre de reproduire en 20 min.
