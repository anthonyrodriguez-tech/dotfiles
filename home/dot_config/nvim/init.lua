-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : Neovim entry point. One-liner per LazyVim convention; the real
--         work happens in lua/config/lazy.lua.
-- WHERE : home/dot_config/nvim/init.lua  →  ~/.config/nvim/init.lua
-- WHY   : Keeping init.lua trivial means every concern (bootstrap, options,
--         keymaps, autocmds, plugin specs) is reachable from a single
--         well-known path under lua/.
-- ─────────────────────────────────────────────────────────────────────────

require("config.lazy")
