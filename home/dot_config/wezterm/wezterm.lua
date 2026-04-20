-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : WezTerm config entry point. Composes sub-modules into one config.
-- WHERE : home/dot_config/wezterm/wezterm.lua  →  ~/.config/wezterm/wezterm.lua
-- WHY   : WezTerm loads exactly one Lua file. Topic-specific concerns
--         (look, OS plumbing, keymaps) live in sibling modules so this
--         file stays under 30 lines and reviews are scoped.
-- ─────────────────────────────────────────────────────────────────────────

local wezterm = require 'wezterm'

-- Make `require 'appearance'` etc. resolve siblings of this file.
package.path = wezterm.config_dir .. '/?.lua;' .. package.path

-- Newer API; degrades gracefully on older wezterm.
local config = wezterm.config_builder and wezterm.config_builder() or {}

require('appearance').apply(config, wezterm)
require('platform').apply(config, wezterm)
require('keybindings').apply(config, wezterm)

return config
