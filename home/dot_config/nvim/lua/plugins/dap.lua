-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : DAP overlay — wire up netcoredbg so F5 just works on a .csproj.
-- WHERE : home/dot_config/nvim/lua/plugins/dap.lua
-- WHY   : LazyVim's `extras.dap.core` (enabled in lazyvim.json) ships
--         nvim-dap + nvim-dap-ui + dap-virtual-text. We only need to
--         declare the .NET adapter; everything else (UI, breakpoints,
--         step controls) is already bound under <leader>d.
-- ─────────────────────────────────────────────────────────────────────────

return {
    {
        "mfussenegger/nvim-dap",
        opts = function()
            local dap = require("dap")

            -- netcoredbg is installed by mason (see lsp.lua ensure_installed).
            dap.adapters.coreclr = {
                type    = "executable",
                command = vim.fn.exepath("netcoredbg"),
                args    = { "--interpreter=vscode" },
            }

            dap.configurations.cs = {
                {
                    type    = "coreclr",
                    name    = "launch - netcoredbg",
                    request = "launch",
                    program = function()
                        return vim.fn.input(
                            "Path to dll: ",
                            vim.fn.getcwd() .. "/bin/Debug/",
                            "file"
                        )
                    end,
                },
            }
        end,
    },
}
