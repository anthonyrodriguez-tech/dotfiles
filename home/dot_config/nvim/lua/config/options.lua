-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : vim option overrides — added on top of LazyVim's defaults.
-- WHERE : home/dot_config/nvim/lua/config/options.lua
-- WHY   : LazyVim sets sensible defaults (it loads its options.lua FIRST,
--         then ours). Don't duplicate what LazyVim already sets — only
--         override or add what we want different.
--
-- Note on clipboard=unnamedplus:
--   • Linux desktop : needs xclip OR wl-clipboard (Wayland)
--   • macOS         : works out of the box (uses pbcopy/pbpaste)
--   • MSYS2/Windows : needs win32yank.exe on $PATH (installed in Phase 9)
--   If none are present, yanks silently stay in vim's own register.
-- ─────────────────────────────────────────────────────────────────────────

local opt = vim.opt

opt.relativenumber = true
opt.scrolloff      = 8           -- always keep 8 lines of context
opt.sidescrolloff  = 8
opt.clipboard      = "unnamedplus"
opt.confirm        = true        -- prompt instead of erroring on :q with unsaved changes
opt.wrap           = false
opt.tabstop        = 4
opt.shiftwidth     = 4
opt.expandtab      = true
opt.smartindent    = true

-- Render trailing whitespace and tabs so we notice them.
opt.list      = true
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }

-- Always reserve the sign column so the layout doesn't jump when
-- diagnostics/git signs appear.
opt.signcolumn = "yes"

-- File handling — persistent undo, no swap, no backup. Git is our backstop.
opt.undofile = true
opt.swapfile = false
opt.backup   = false
