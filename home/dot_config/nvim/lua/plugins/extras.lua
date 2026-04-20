-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : misc plugins that don't warrant their own file.
-- WHERE : home/dot_config/nvim/lua/plugins/extras.lua
-- WHY   :
--   • oil.nvim     — edit the filesystem like a buffer (vim-vinegar++).
--   • which-key    — register groups for our personal <leader>y / <leader>d
--                    namespaces declared in lua/config/keymaps.lua.
-- ─────────────────────────────────────────────────────────────────────────

return {
    -- oil — `-` opens the parent dir as an editable buffer.
    {
        "stevearc/oil.nvim",
        cmd  = "Oil",
        opts = {
            default_file_explorer = false,        -- keep neo-tree as the default tree
            view_options          = { show_hidden = true },
            keymaps = {
                ["g?"]  = "actions.show_help",
                ["<CR>"] = "actions.select",
                ["-"]   = "actions.parent",
                ["q"]   = "actions.close",
            },
        },
        keys = {
            { "-", function() require("oil").open() end, desc = "Open parent (oil)" },
        },
    },

    -- which-key groups for personal-keymap namespaces.
    {
        "folke/which-key.nvim",
        opts = function(_, opts)
            opts.spec = opts.spec or {}
            vim.list_extend(opts.spec, {
                { "<leader>y", group = "yank/clipboard"    },
                { "<leader>d", group = "delete (black hole)" },
            })
            return opts
        end,
    },
}
