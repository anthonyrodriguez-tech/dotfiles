-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : visual settings — colors, font, tab bar, padding, cursor.
-- WHERE : home/dot_config/wezterm/appearance.lua
-- WHY   : Catppuccin Mocha is the project-wide palette (also bat, starship,
--         lazygit, nvim). JetBrainsMono Nerd Font is the only required
--         font family — its glyphs are used by starship modules, lazygit
--         tab bar, telescope file icons.
-- ─────────────────────────────────────────────────────────────────────────

local M = {}

function M.apply(config, wezterm)
    -- ── Color scheme ─────────────────────────────────────────────────────
    -- Built-in since wezterm 20220903; no plugin needed.
    config.color_scheme = 'Catppuccin Mocha'

    -- ── Font ─────────────────────────────────────────────────────────────
    -- Auto bold/italic discovery. Fallback chain so the config still
    -- renders if the Nerd Font isn't installed yet (icons will tofu).
    config.font = wezterm.font_with_fallback({
        { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
        'JetBrains Mono',
        'Menlo',
        'Consolas',
    })
    config.font_size = 13.0
    config.line_height = 1.05

    -- ── Tab bar ──────────────────────────────────────────────────────────
    -- Plain bar (not OS-native) so it looks identical across mac/linux/win.
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = false
    config.hide_tab_bar_if_only_one_tab = true
    config.tab_max_width = 32
    config.show_new_tab_button_in_tab_bar = false

    -- ── Window chrome ────────────────────────────────────────────────────
    config.window_padding = { left = 8, right = 8, top = 4, bottom = 4 }
    config.window_decorations = 'RESIZE'      -- no titlebar; keeps resize border
    config.window_background_opacity = 1.0    -- bump to 0.95 for translucent
    config.adjust_window_size_when_changing_font_size = false

    -- ── Cursor ───────────────────────────────────────────────────────────
    config.default_cursor_style = 'SteadyBar'
    config.cursor_blink_rate = 0

    -- ── Buffer / bell ────────────────────────────────────────────────────
    config.scrollback_lines = 50000
    config.audible_bell = 'Disabled'
    config.warn_about_missing_glyphs = false
end

return M
