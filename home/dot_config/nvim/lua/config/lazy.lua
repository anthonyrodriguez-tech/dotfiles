-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : lazy.nvim bootstrap + LazyVim base + our plugin overlay.
-- WHERE : home/dot_config/nvim/lua/config/lazy.lua
-- WHY   : LazyVim ships ~80 plugins out of the box. We layer our own
--         specs in lua/plugins/*.lua (imported via { import = "plugins" })
--         so they're picked up automatically without touching this file.
-- ─────────────────────────────────────────────────────────────────────────

-- ── Bootstrap lazy.nvim if missing ───────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- ── Setup ────────────────────────────────────────────────────────────────
require("lazy").setup({
    spec = {
        -- LazyVim base — entire pre-curated plugin suite.
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        -- Our overlay (everything under lua/plugins/*.lua is auto-imported).
        { import = "plugins" },
    },

    defaults = {
        lazy = false,     -- LazyVim handles lazy-loading itself
        version = false,  -- always latest; pin via lazy-lock.json (per-machine)
    },

    install = { colorscheme = { "catppuccin-mocha", "habamax" } },

    -- Background update checks; notification suppressed (use :Lazy instead).
    checker = { enabled = true, notify = false },

    performance = {
        rtp = {
            -- Disable runtime plugins we never use.
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
})
