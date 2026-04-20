-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : personal keymap additions on top of LazyVim's defaults.
-- WHERE : home/dot_config/nvim/lua/config/keymaps.lua
-- WHY   : LazyVim binds <leader>f, <leader>g, <leader>l, … (see :Telescope
--         keymaps). We keep all of those and add a small set that shows up
--         under <leader>y (yank/clipboard) and <leader>d (black-hole delete)
--         — declared as which-key groups in lua/plugins/extras.lua.
-- ─────────────────────────────────────────────────────────────────────────

local map = vim.keymap.set

-- ── Stay centred on long jumps ───────────────────────────────────────────
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centred)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centred)"   })
map("n", "n",     "nzzzv",   { desc = "Next match (centred)"     })
map("n", "N",     "Nzzzv",   { desc = "Prev match (centred)"     })

-- ── Move visual selection up/down with auto-reindent ─────────────────────
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up"   })

-- ── System clipboard without clobbering the unnamed register ─────────────
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n",          "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole"   })

-- ── Quick ESC from insert ────────────────────────────────────────────────
map("i", "jk", "<Esc>", { desc = "ESC alias" })
