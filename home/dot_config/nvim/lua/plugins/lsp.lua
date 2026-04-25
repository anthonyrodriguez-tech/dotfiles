-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : LSP server overlay — .NET / DevOps stack.
-- WHERE : home/dot_config/nvim/lua/plugins/lsp.lua
-- WHY   : LazyVim wires up nvim-lspconfig + mason; we just declare which
--         servers to install and any per-server settings. Tools (linters,
--         formatters, debuggers) are appended to mason.ensure_installed
--         so mason-tool-installer picks them up on first run.
--
-- MSYS2 caveat:
--   • prettier / stylua / shfmt install fine via mason (Go binaries).
--   • netcoredbg ships only an x64 build — works on Safran but won't on
--     ARM Windows. Document if the user moves to ARM.
--   • omnisharp downloads .NET 6 runtime alongside; needs ~100 MB, slow on
--     proxy-throttled networks.
-- ─────────────────────────────────────────────────────────────────────────

return {
    -- Mason: download / install LSP servers, formatters, linters, DAP adapters.
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "csharpier",       -- .NET formatter
                "netcoredbg",      -- .NET debugger (used by dap.lua)
                "shfmt",           -- shell formatter
                "stylua",          -- lua formatter
                "prettier",        -- web formatter
                "yamllint",        -- yaml linter
                "actionlint",      -- GitHub Actions linter
            })
        end,
    },

    -- LSP server configs. LazyVim merges these into its own defaults.
    --
    -- `opts` is a function (not a table) so the schemastore require below
    -- runs AFTER lazy.nvim has installed dependencies — a top-level
    -- require would fire during spec discovery, before schemastore exists.
    {
        "neovim/nvim-lspconfig",
        dependencies = { "b0o/schemastore.nvim" },
        opts = function(_, opts)
            opts.servers = vim.tbl_deep_extend("force", opts.servers or {}, {
                -- .NET — omnisharp ships a .NET 6 runtime via mason. The
                -- newer roslyn_ls is faster but harder to install (no
                -- mason package); switch via seblj/roslyn.nvim later if needed.
                omnisharp = {},

                -- TypeScript / JavaScript (renamed from `tsserver` in
                -- nvim-lspconfig late 2024).
                ts_ls = {},

                -- Infrastructure
                terraformls = {},
                dockerls    = {},

                -- Other languages
                gopls   = {},
                bashls  = {},
                lua_ls  = {},

                -- YAML — augment with k8s + GitHub Actions + GitLab CI
                -- schemas via schemastore.nvim. Disable yamlls's own
                -- schemaStore so the two catalogs don't fight.
                yamlls = {
                    settings = {
                        yaml = {
                            schemaStore = { enable = false, url = "" },
                            schemas     = require("schemastore").yaml.schemas(),
                        },
                    },
                },
            })
            return opts
        end,
    },
}
