-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : autocmds added on top of LazyVim's defaults.
-- WHERE : home/dot_config/nvim/lua/config/autocmds.lua
-- WHY   : Two small QoL hooks. LazyVim has its own list at
--         lazyvim.config.autocmds — don't duplicate; add only.
-- ─────────────────────────────────────────────────────────────────────────

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlight the yanked region so it's visible what got copied.
autocmd("TextYankPost", {
    group = augroup("highlight_yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank({ timeout = 200 })
    end,
})

-- Strip trailing whitespace on save — except where it's load-bearing
-- (markdown trailing spaces = hard-break; diff/gitcommit are read-only).
autocmd("BufWritePre", {
    group = augroup("trim_whitespace", { clear = true }),
    callback = function(ev)
        local skip = { markdown = true, diff = true, gitcommit = true, mail = true }
        if skip[vim.bo[ev.buf].filetype] then return end
        local cur = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[silent! keeppatterns %s/\s\+$//e]])
        pcall(vim.api.nvim_win_set_cursor, 0, cur)
    end,
})
