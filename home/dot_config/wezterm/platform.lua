-- ─────────────────────────────────────────────────────────────────────────
-- WHAT  : per-OS branches — default shell, font rendering target, keyboard.
-- WHERE : home/dot_config/wezterm/platform.lua
-- WHY   : zsh is the universal shell (phase 2), but the *path* differs.
--         On Safran Windows (no admin) we launch MSYS2 zsh by absolute
--         path; CHERE_INVOKING=1 keeps the spawn cwd instead of jumping
--         to $HOME on shell start.
-- ─────────────────────────────────────────────────────────────────────────

local M = {}

local function is_mac(t)     return t:find('darwin')  ~= nil end
local function is_linux(t)   return t:find('linux')   ~= nil end
local function is_windows(t) return t:find('windows') ~= nil end

-- Probe well-known MSYS2 locations until one resolves. Returns path or nil.
-- Order chosen to favour Scoop (the install path used on Safran).
local function find_msys2_zsh()
    local home = os.getenv('USERPROFILE') or ''
    local candidates = {
        home .. '\\scoop\\apps\\msys2\\current\\usr\\bin\\zsh.exe',
        'C:\\msys64\\usr\\bin\\zsh.exe',
        'C:\\tools\\msys64\\usr\\bin\\zsh.exe',
    }
    for _, p in ipairs(candidates) do
        local f = io.open(p, 'r')
        if f then f:close(); return p end
    end
    return nil
end

function M.apply(config, wezterm)
    local triple = wezterm.target_triple

    if is_mac(triple) then
        config.default_prog = { '/bin/zsh', '-l' }
        config.freetype_load_target = 'Light'
        config.front_end = 'WebGpu'   -- smoother on M-series
        -- Make Alt act as Meta so zsh / readline word-jumps work.
        config.send_composed_key_when_left_alt_is_pressed  = false
        config.send_composed_key_when_right_alt_is_pressed = false

    elseif is_linux(triple) then
        config.default_prog = { '/usr/bin/zsh', '-l' }
        config.freetype_load_target = 'Normal'

    elseif is_windows(triple) then
        local msys_zsh = find_msys2_zsh()
        if msys_zsh then
            -- -li = login + interactive. login pulls /etc/profile (sets
            -- PATH for /usr/bin tools); interactive sources our .zshrc.
            config.default_prog = { msys_zsh, '-li' }
        else
            -- First-boot fallback: PowerShell with a banner pointing to
            -- the bootstrap script. Users see the message instead of
            -- a silent crash.
            config.default_prog = {
                'powershell.exe', '-NoExit', '-Command',
                'Write-Host "MSYS2 zsh not found. Run scripts/bootstrap-windows.ps1 to install." -ForegroundColor Yellow'
            }
        end
        -- MSYSTEM tells /etc/profile which subsystem layout to load
        -- (MSYS = generic POSIX, vs. UCRT64/MINGW64 for native builds).
        -- CHERE_INVOKING preserves the cwd MSYS2 was spawned in.
        config.set_environment_variables = {
            MSYSTEM = 'MSYS',
            CHERE_INVOKING = '1',
        }
        config.freetype_load_target = 'Normal'
    end
end

return M
