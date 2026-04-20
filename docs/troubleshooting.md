# Troubleshooting

Symptoms → causes → fixes. Ordered by how likely you'll hit each one.

---

## Neovim clipboard doesn't sync with the system

`<leader>y` lands in the system clipboard only if Neovim knows how to
talk to it. Requirements:

| OS                    | Required binary      | Install                                          |
|-----------------------|----------------------|--------------------------------------------------|
| macOS                 | `pbcopy` / `pbpaste` | built-in                                         |
| Linux X11             | `xclip` or `xsel`    | `apt install xclip` / equivalent                 |
| Linux Wayland         | `wl-copy` / `wl-paste` | `apt install wl-clipboard`                     |
| Windows MSYS2         | `win32yank.exe`      | `scoop install win32yank` (bootstrap-windows.ps1 attempts this) |

Check: `:checkhealth` inside nvim, look at the "Clipboard" section.

---

## Mason installs a tool and it still isn't found (`exepath(...) == ""`)

Two common causes:

1. **MSYS2 PATH ordering**. Mason installs under
   `~/.local/share/nvim/mason/bin`; MSYS2's `$PATH` often puts
   `/usr/bin` first and the symlinks Mason ships are thin shell scripts.
   Confirm with `:Mason` that the tool is listed as "Installed" and
   `echo $PATH` shows the Mason bin dir.
2. **ARM Windows**. Some Mason packages are x86_64-only (notably
   `netcoredbg`). They won't install on ARM. Workaround: install the
   tool manually into `$HOME/.local/bin` and point nvim at it.

---

## `chezmoi apply` says "templating error: promptStringOnce not defined"

`promptStringOnce` / `promptChoiceOnce` are only available during
`chezmoi init`, not during regular `apply`. If you added a new prompt,
it must live in `home/.chezmoi.toml.tmpl`, not in a downstream template.

Fix: add the prompt to `.chezmoi.toml.tmpl`, capture it as a data key
(e.g. `proxy_http`), then reference it downstream as `{{ .proxy_http }}`.

---

## `lazy-lock.json` keeps showing up as "modified" after `:Lazy update`

That's intentional — the lock file pins plugin SHAs and is **committed**
on purpose (see ADR-004). When you run `:Lazy update`, the file changes
to reflect the new SHAs. Commit it or revert it; don't put it in
`.gitignore`.

---

## WezTerm on Windows opens PowerShell instead of zsh

`platform.lua` walks three candidate paths:
- `%USERPROFILE%\scoop\apps\msys2\current\usr\bin\zsh.exe`
- `C:\msys64\usr\bin\zsh.exe`
- `C:\tools\msys64\usr\bin\zsh.exe`

If MSYS2 lives elsewhere (unlikely, but possible on locked-down
corporate images), edit `platform.lua` and add your path to the list.
A banner in PowerShell tells you that no MSYS2 was found.

Also verify `MSYSTEM=MSYS` is set in the launched environment — if
zsh starts but the prompt looks off, MSYSTEM was probably left at its
default of `MINGW64` (which is *not* what our config assumes).

---

## Starship prompt shows `[?]` squares instead of icons

Nerd Font missing or the terminal isn't using it. Check:
- WezTerm: `appearance.lua` sets `JetBrainsMono Nerd Font`; verify the
  font is installed (`fc-list | grep -i jetbrains` on mac/linux, look
  in "Fonts" control panel on Windows).
- Reload the font cache: `fc-cache -fv` on linux, log out/in on macOS
  after a `brew install --cask font-jetbrains-mono-nerd-font`.

---

## `compinit` complains about insecure directories

Zsh refuses to load completions from world-writable dirs. Fix:
```sh
chmod go-w ~/.local/share/zsh/site-functions
chmod go-w "$(brew --prefix)/share/zsh"
```

Or, if you *know* the dirs are safe (corporate shared drive where perms
are out of your control), add `compinit -u` to `completion.zsh`
**temporarily** — don't leave it in.

---

## `chezmoi init` prompts keep firing on every run

`promptStringOnce` is supposed to persist after the first answer. It
does — but only if the answer actually got written to
`~/.config/chezmoi/chezmoi.toml`. If you interrupted the first init
(Ctrl-C), the file is partial. Delete it and rerun:

```sh
rm ~/.config/chezmoi/chezmoi.toml
chezmoi init
```

---

## Scoop install fails with "no admin privileges" message

You're running PowerShell as administrator. Don't. Open a non-admin
PowerShell (Start Menu → PowerShell, no right-click-as-admin) and
re-run the bootstrap.

---

## `delta` not invoked — diffs look plain

Check in that order:
- `git config --get core.pager` should return `delta`.
- `command -v delta` must resolve; otherwise install it
  (`brew install git-delta`, `scoop install delta`, or via cargo).
- If lazygit shows plain diffs but CLI `git diff` is colorised, the
  fault is in `lazygit/config.yml` — after the first run lazygit may
  have migrated `git.paging` into `git.pagers`, which is expected.
