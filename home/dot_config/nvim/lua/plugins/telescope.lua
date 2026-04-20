-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : telescope extensions — fzf-native sorter + file_browser.
-- WHERE : home/dot_config/nvim/lua/plugins/telescope.lua
-- WHY   : LazyVim sets telescope up with sensible defaults. We add:
--           • fzf-native — much faster than the default Lua sorter
--           • file_browser — netrw replacement; <leader>fe to open
-- ─────────────────────────────────────────────────────────────────────────

return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            { "nvim-telescope/telescope-file-browser.nvim" },
        },
        opts = function(_, opts)
            opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, {
                fzf = {
                    fuzzy                   = true,
                    override_generic_sorter = true,
                    override_file_sorter    = true,
                    case_mode               = "smart_case",
                },
                file_browser = {
                    hijack_netrw = true,
                },
            })
            return opts
        end,
        config = function(_, opts)
            local telescope = require("telescope")
            telescope.setup(opts)
            -- pcall: extensions may not have built yet on first run; fail silently.
            pcall(telescope.load_extension, "fzf")
            pcall(telescope.load_extension, "file_browser")
        end,
        keys = {
            {
                "<leader>fe",
                function() require("telescope").extensions.file_browser.file_browser() end,
                desc = "File browser",
            },
        },
    },
}
