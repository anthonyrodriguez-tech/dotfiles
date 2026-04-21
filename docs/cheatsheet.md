# Cheat-sheet

Quick reference for the muscle memory encoded in this repo. Open in a
split, `grep` the section you need, close.

---

## WezTerm (leader = `Ctrl-a`)

| Chord              | Action                           |
|--------------------|----------------------------------|
| `Leader \|` / `\`  | split horizontal (side-by-side)  |
| `Leader -`         | split vertical (stacked)         |
| `Leader h/j/k/l`   | move between panes               |
| `Leader z`         | zoom current pane                |
| `Leader x`         | close pane (confirm)             |
| `Leader c`         | new tab                          |
| `Leader n` / `p`   | next / previous tab              |
| `Leader 0-9`       | jump to tab N                    |
| `Leader [`         | enter copy mode                  |
| `Leader Shift-R`   | reload config                    |
| `Leader s`         | fuzzy-pick workspace             |
| `Ctrl-Shift-C/V`   | copy / paste                     |

Leader timeout: **1000 ms**. If a chord "doesn't register", press
`Ctrl-a` slightly harder — you might be tapping past the timeout.

---

## Neovim — personal keymaps (on top of LazyVim defaults)

| Mode    | Key         | Action                                |
|---------|-------------|---------------------------------------|
| n       | `jk`        | leave insert mode (as `<Esc>`)        |
| n       | `<C-d>`     | half-page down + recenter             |
| n       | `<C-u>`     | half-page up + recenter               |
| n       | `n` / `N`   | next/prev search + recenter           |
| v       | `J` / `K`   | move selection down / up              |
| n / v   | `<leader>y` | yank to system clipboard              |
| n / v   | `<leader>Y` | yank line to system clipboard         |
| n / v   | `<leader>d` | delete into black-hole register       |
| n       | `-`         | open parent dir (`oil.nvim`)          |
| n       | `<leader>fe`| file browser (telescope)              |

LazyVim defaults worth knowing: `<leader>ff` files, `<leader>fg` live
grep, `<leader>e` file explorer, `<leader>gg` lazygit, `<leader>xx`
trouble diagnostics.

Dashboard quick-actions: `f` find, `n` new, `g` grep, `r` recent,
`p` projects, `c` config, `L` Lazy, `q` quit.

---

## Lazygit (`lg` from zsh)

| Key         | Action                                 |
|-------------|----------------------------------------|
| `<space>`   | stage / unstage file or hunk           |
| `a`         | toggle staged / unstaged               |
| `c`         | commit                                 |
| `C`         | commit with $EDITOR (custom binding)   |
| `A`         | amend last commit                      |
| `P`         | push                                   |
| `p`         | pull                                   |
| `+`         | fetch                                  |
| `<tab>`     | next panel (custom `togglePanel`)      |
| `<esc>`     | return / cancel (custom)               |
| `q`         | quit (custom)                          |
| `?`         | help — see everything else             |

Delta is the pager, so diffs are syntax-highlighted just like the
terminal `git diff`.

---

## Zsh readline (emacs mode)

| Raccourci         | Action                                      |
|-------------------|---------------------------------------------|
| `Ctrl-P` / `↑`   | historique préfixé vers le haut             |
| `Ctrl-N` / `↓`   | historique préfixé vers le bas              |
| `Ctrl-←`         | mot précédent                               |
| `Ctrl-→`         | mot suivant                                 |
| `Alt-←`          | mot précédent (macOS)                       |
| `Alt-→`          | mot suivant (macOS)                         |
| `Ctrl-U`         | supprimer de la position au début de ligne  |
| `Ctrl-K`         | supprimer de la position à la fin de ligne  |
| `Ctrl-X Ctrl-E`  | ouvrir la ligne en cours dans `$EDITOR`     |
| `Ctrl-R`         | fzf — recherche dans l'historique           |
| `Ctrl-T`         | fzf — recherche de fichier                  |
| `Alt-C`          | fzf — `cd` interactif                       |

---

## Zsh aliases

### Git
| Alias | Expands to                                |
|-------|-------------------------------------------|
| `g`   | `git`                                     |
| `gs`  | `git status`                              |
| `gd`  | `git diff`                                |
| `gc`  | `git commit`                              |
| `gp`  | `git push`                                |
| `gl`  | `git pull`                                |
| `lg`  | `lazygit`                                 |

### Files / navigation
| Alias  | Expands to                              |
|--------|-----------------------------------------|
| `ls`   | `eza --group-directories-first`         |
| `ll`   | `eza -l --git --group-directories-first`|
| `la`   | `eza -la --git --group-directories-first`|
| `lt`   | `eza --tree --level=2 ...`              |
| `cat`  | `bat --paging=never`                    |

Guarded: if `eza`/`bat`/`fd` isn't installed (rare, e.g. fresh MSYS2),
the alias silently falls back to the GNU version. Note: no `grep` alias —
invoke `rg` directly.

### Chezmoi
| Alias  | Expands to              |
|--------|-------------------------|
| `cz`   | `chezmoi`               |
| `czd`  | `chezmoi diff`          |
| `cza`  | `chezmoi apply -v`      |
| `cze`  | `chezmoi edit`          |
| `czcd` | `chezmoi cd` (source)   |

### Misc
| Alias  | Expands to              |
|--------|-------------------------|
| `v`    | `nvim`                  |
| `vim`  | `nvim`                  |
| `k`    | `kubectl`               |
| `tf`   | `terraform`             |
| `cc`   | `claude`                |

---

## Functions (zsh)

- `mkcd <dir>` — mkdir + cd in one.
- `fkill` — fuzzy process picker, sends SIGTERM.
- `fbranch` — fuzzy `git switch` across local branches.
- `extract <archive>` — universal archive extractor.

---

## Git aliases (via `git <alias>`)

| Alias     | Action                                               |
|-----------|------------------------------------------------------|
| `s`       | short status                                         |
| `co`/`sw` | checkout / switch                                    |
| `br`      | branch                                               |
| `ci`      | commit                                               |
| `ap`      | add --patch                                          |
| `lg`      | pretty graph                                         |
| `last`    | last commit with stat                                |
| `sync`    | fetch --all --prune && pull --rebase --autostash     |
| `undo`    | soft reset to HEAD~1                                 |
| `nuke`    | hard reset to upstream (destructive!)                |
| `cleanup` | delete local branches merged into main/master       |
| `fix`     | amend --no-edit                                      |

---

## Claude Code

- `/review-pr [N]` — full PR review (diff + lint + tests), delegates
  Terraform to the `terraform-reviewer` subagent.
- `cc` (zsh alias) launches Claude Code.

After install: `claude auth login` once per machine.
