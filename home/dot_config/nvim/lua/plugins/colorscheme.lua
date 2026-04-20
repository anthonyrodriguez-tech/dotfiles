-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : force Catppuccin Mocha as the default colorscheme.
-- WHERE : home/dot_config/nvim/lua/plugins/colorscheme.lua
-- WHY   : Project-wide palette consistency (wezterm, starship, lazygit, bat
--         all use Catppuccin Mocha). LazyVim uses tokyonight by default —
--         the second spec below tells it to use catppuccin-mocha instead.
-- ─────────────────────────────────────────────────────────────────────────

return {
    -- The plugin itself, with integrations enabled for everything we use.
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,                -- load before any UI plugin
        opts = {
            flavour = "mocha",
            integrations = {
                cmp           = true,
                gitsigns      = true,
                neotree       = true,
                telescope     = { enabled = true },
                treesitter    = true,
                which_key     = true,
                mason         = true,
                noice         = true,
                notify        = true,
                native_lsp    = {
                    enabled = true,
                    underlines = { errors = { "undercurl" } },
                },
                dap           = true,
                dap_ui        = true,
                harpoon       = true,
                snacks        = { enabled = true },
            },
        },
    },

    -- Tell LazyVim to use it.
    {
        "LazyVim/LazyVim",
        opts = { colorscheme = "catppuccin-mocha" },
    },
}
