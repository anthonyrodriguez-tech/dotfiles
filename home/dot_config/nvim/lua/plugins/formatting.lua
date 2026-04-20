-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : conform.nvim — format on save, per-filetype formatter map.
-- WHERE : home/dot_config/nvim/lua/plugins/formatting.lua
-- WHY   : LazyVim ships conform.nvim already; we only declare which
--         formatter to run per filetype, plus shfmt's tab width.
--         lsp_format = "fallback" means: if no conform formatter is
--         registered for a filetype, fall back to the LSP's own
--         textDocument/formatting (e.g. roslyn for C# if csharpier missing).
-- ─────────────────────────────────────────────────────────────────────────

return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                cs                  = { "csharpier" },
                javascript          = { "prettier" },
                typescript          = { "prettier" },
                javascriptreact     = { "prettier" },
                typescriptreact     = { "prettier" },
                json                = { "prettier" },
                jsonc               = { "prettier" },
                yaml                = { "prettier" },
                markdown            = { "prettier" },
                html                = { "prettier" },
                css                 = { "prettier" },
                lua                 = { "stylua" },
                sh                  = { "shfmt" },
                bash                = { "shfmt" },
                zsh                 = { "shfmt" },
                terraform           = { "terraform_fmt" },
                tf                  = { "terraform_fmt" },
                ["terraform-vars"]  = { "terraform_fmt" },
            },
            format_on_save = {
                timeout_ms  = 1000,
                lsp_format  = "fallback",
            },
            formatters = {
                shfmt = {
                    prepend_args = { "-i", "4" },   -- 4-space indent, matches editorconfig
                },
            },
        },
    },
}
