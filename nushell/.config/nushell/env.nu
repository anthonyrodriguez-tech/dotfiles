# env.nu — chargé avant config.nu

$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.local/bin" | uniq)
