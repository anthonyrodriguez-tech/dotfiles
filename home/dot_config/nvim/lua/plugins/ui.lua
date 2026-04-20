-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : UI tweaks — themed lualine, snacks dashboard with quick actions.
-- WHERE : home/dot_config/nvim/lua/plugins/ui.lua
-- WHY   : LazyVim ≥ 12 already uses snacks.nvim for the dashboard; we just
--         redefine the action keys for our workflow (quick access to
--         config, recent files, projects, lazy).
-- ─────────────────────────────────────────────────────────────────────────

return {
    -- Themed status line.
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
                theme = "catppuccin",
            })
            return opts
        end,
    },

    -- Dashboard quick actions.
    {
        "folke/snacks.nvim",
        opts = {
            dashboard = {
                preset = {
                    keys = {
                        { icon = " ", key = "f", desc = "Find File",
                          action = ":lua Snacks.dashboard.pick('files')" },
                        { icon = " ", key = "n", desc = "New File",
                          action = ":ene | startinsert" },
                        { icon = " ", key = "g", desc = "Find Text",
                          action = ":lua Snacks.dashboard.pick('live_grep')" },
                        { icon = " ", key = "r", desc = "Recent Files",
                          action = ":lua Snacks.dashboard.pick('oldfiles')" },
                        { icon = " ", key = "p", desc = "Projects",
                          action = ":lua Snacks.dashboard.pick('projects')" },
                        { icon = " ", key = "c", desc = "Config",
                          action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
                        { icon = "󰒲 ", key = "L", desc = "Lazy",   action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Quit",   action = ":qa" },
                    },
                },
            },
        },
    },
}
