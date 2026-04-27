-- Per-OS branches: default shell + font rendering.
-- Linux/WSL: zsh. Windows native: pwsh (PowerShell 7), powershell.exe fallback.

local M = {}

local function is_linux(t)   return t:find('linux')   ~= nil end
local function is_windows(t) return t:find('windows') ~= nil end

local function find_pwsh()
    local home = os.getenv('USERPROFILE') or ''
    local candidates = {
        home .. '\\scoop\\apps\\pwsh\\current\\pwsh.exe',
        'C:\\Program Files\\PowerShell\\7\\pwsh.exe',
    }
    for _, p in ipairs(candidates) do
        local f = io.open(p, 'r')
        if f then f:close(); return p end
    end
    return nil
end

function M.apply(config, wezterm)
    local triple = wezterm.target_triple

    if is_linux(triple) then
        config.default_prog = { '/usr/bin/zsh', '-l' }
        config.freetype_load_target = 'Normal'

    elseif is_windows(triple) then
        local pwsh = find_pwsh()
        if pwsh then
            config.default_prog = { pwsh, '-NoLogo' }
        else
            -- Fallback: bare powershell.exe with a banner pointing at the bootstrap.
            config.default_prog = {
                'powershell.exe', '-NoLogo', '-NoExit', '-Command',
                'Write-Host "pwsh not found. Run scripts/install.ps1 to install." -ForegroundColor Yellow'
            }
        end
        config.freetype_load_target = 'Normal'
    end
end

return M
