# env.nu — chargé avant config.nu

$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.local/bin" | uniq)

# ── Starship ──────────────────────────────────────────────────────────────────
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
