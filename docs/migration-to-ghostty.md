# Migration plan: WezTerm → Ghostty

**Status:** not started. Target: once Ghostty ships stable Windows
binaries (tracked at github.com/ghostty-org/ghostty).

Captured here so that the day we flip, we don't have to re-learn
what our WezTerm config actually does.

---

## Why Ghostty (eventually)

- Pure-GPU renderer, lower latency than WezTerm on Linux.
- Configuration is a single flat key-value file (no Lua).
- Shell integration is built-in — no more manual `printf` OSC
  sequences for cwd tracking.

## Why not *yet*

- **Windows support is still experimental.** Safran laptop is the
  daily driver; until Ghostty runs natively on Win + MSYS2 like
  WezTerm does, this is a non-starter.
- We rely on WezTerm's Lua config for MSYS2-zsh autodetection
  (`platform.lua`, three-path walk). Ghostty's config language can't
  express that — we'd need to pre-compute the path at install time
  and bake it into the config. Doable; just different.

---

## What to port

### 1. Appearance (`appearance.lua`)

| WezTerm                              | Ghostty (guess)                    |
|--------------------------------------|------------------------------------|
| `color_scheme = "Catppuccin Mocha"`  | `theme = catppuccin-mocha`         |
| `font = wezterm.font_with_fallback(…)` | `font-family = JetBrainsMono Nerd Font` |
| `font_size = 13`                     | `font-size = 13`                   |
| `window_decorations = "RESIZE"`      | `window-decoration = false`        |
| `use_fancy_tab_bar = false`          | Ghostty has no fancy tab bar       |
| `default_cursor_style = "SteadyBar"` | `cursor-style = bar`               |
| `scrollback_lines = 50000`           | `scrollback-limit = 50000`         |

### 2. Leader chords (`keybindings.lua`)

This is where the work is. Ghostty's keybinding DSL is per-line
`keybind = ctrl+a>|=unbind` (example) and doesn't support stateful
leader modes as cleanly as WezTerm.

Plan: implement the splits/panes (`|`, `-`, `h/j/k/l`, `z`, `x`) as
the native Ghostty split keybinds (`ctrl+shift+enter` etc.) rather
than porting the exact leader chords. Lose `Leader s` fuzzy
workspace — not worth reimplementing.

For the tabs (`Leader n/p/0-9`) Ghostty has direct bindings
(`ctrl+shift+tab`, `ctrl+1..9`) — use those.

### 3. Shell detection (`platform.lua`)

Drop the Lua autodetect. Instead, the bootstrap script (per OS) writes
the correct `command = ...` line into `~/.config/ghostty/config`
during install, since by that point we know where MSYS2 lives.

### 4. Leftover decisions

- Copy/paste: `Ctrl-Shift-C/V` works natively — no config needed.
- Copy mode: Ghostty ships a kitty-like selection mode. Bind it to
  `Leader [` if we still want the muscle memory.

---

## Sequencing

1. Ghostty ships a Windows native binary that handles MSYS2 launching
   (either out of the box or via `command =`).
2. Port `appearance.lua` → `config` file. One commit.
3. Rewrite keybinds — ~20 chords, maybe half a day. One commit.
4. Update `bootstrap-{arch,ubuntu,windows}` scripts to install Ghostty
   + drop WezTerm install step. One commit.
5. Delete `home/dot_config/wezterm/` and archive it as a tag
   (`pre-ghostty`) so we can roll back if Ghostty regresses.

At that point, bump to a `v1.0.0` tag — Ghostty migration is the last
real infra change we're likely to do in the near term.

---

## Non-goals

- We're **not** going to maintain both WezTerm and Ghostty configs in
  parallel. The day we migrate, WezTerm is gone.
- We're **not** porting the fuzzy workspace picker — it's cute, but
  tmux-with-resurrect covers the same need when we need persistence.
