-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : tmux-like leader bindings + classic clipboard chords.
-- WHERE : home/dot_config/wezterm/keybindings.lua
-- WHY   : Muscle memory for `Ctrl-a` as tmux prefix exists from Linux
--         setups (where real tmux still runs). Mirroring the same prefix
--         here removes friction when WezTerm is the multiplexer
--         (Safran Windows, no tmux).
--
-- Convention used:
--   leader            = LEADER (Ctrl-a, 1000 ms timeout)
--   tmux `prefix |`   = side-by-side panes  → wezterm SplitHorizontal
--   tmux `prefix -`   = stacked panes       → wezterm SplitVertical
--   tmux `prefix [`   = enter copy mode
--   tmux `prefix R`   = reload config
-- ─────────────────────────────────────────────────────────────────────────

local M = {}

function M.apply(config, wezterm)
    local act = wezterm.action

    config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

    config.keys = {
        -- ── splits ───────────────────────────────────────────────────────
        -- '|' = Shift-\ on US/UK; `\` alone is the leader-friendly variant.
        { key = '|',  mods = 'LEADER|SHIFT',
          action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = '\\', mods = 'LEADER',
          action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = '-',  mods = 'LEADER',
          action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

        -- ── pane navigation (vim hjkl) ───────────────────────────────────
        { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left'  },
        { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down'  },
        { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up'    },
        { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

        -- ── pane zoom / close ────────────────────────────────────────────
        { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
        { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

        -- ── tabs ─────────────────────────────────────────────────────────
        { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
        { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1)  },
        { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
        { key = '0', mods = 'LEADER', action = act.ActivateTab(0) },
        { key = '1', mods = 'LEADER', action = act.ActivateTab(1) },
        { key = '2', mods = 'LEADER', action = act.ActivateTab(2) },
        { key = '3', mods = 'LEADER', action = act.ActivateTab(3) },
        { key = '4', mods = 'LEADER', action = act.ActivateTab(4) },
        { key = '5', mods = 'LEADER', action = act.ActivateTab(5) },
        { key = '6', mods = 'LEADER', action = act.ActivateTab(6) },
        { key = '7', mods = 'LEADER', action = act.ActivateTab(7) },
        { key = '8', mods = 'LEADER', action = act.ActivateTab(8) },
        { key = '9', mods = 'LEADER', action = act.ActivateTab(9) },

        -- ── modes / utilities ────────────────────────────────────────────
        -- Copy mode (tmux `prefix [`)
        { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
        -- Reload config (tmux `prefix R`)
        { key = 'R', mods = 'LEADER|SHIFT', action = act.ReloadConfiguration },
        -- Workspace switcher (fuzzy)
        { key = 's', mods = 'LEADER',
          action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },

        -- ── classic clipboard chords (kept; everyone expects them) ───────
        { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
        { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
    }
end

return M
