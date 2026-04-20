-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : luacheck config for this repo.
-- WHERE : .luacheckrc (repo root)
-- WHY   : neovim and wezterm both inject globals that luacheck can't see
--         otherwise. Declare them once, project-wide.
-- ─────────────────────────────────────────────────────────────────────────

std = "lua51"

-- Globals injected by the respective runtimes.
globals = {
    "vim",      -- neovim
    "wezterm",  -- wezterm (inside wezterm.on and require contexts)
    "_G",
}

-- Tolerate long-ish lines — our config files favour aligned columns
-- over strict column width.
max_line_length = 140

-- Skip LazyVim's plugin-lock file (generated).
exclude_files = {
    "home/dot_config/nvim/lazy-lock.json",
    "home/dot_config/nvim/lazyvim.json",
}

-- File-specific overrides.
files["home/dot_config/nvim/lua/plugins/*.lua"] = {
    -- LazyVim plugin specs take `_` as a first arg quite often.
    ignore = { "212/_" },
}
