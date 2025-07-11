local wezterm = require('wezterm')
local config = wezterm.config_builder()
config.color_scheme = 'nord'
config.enable_tab_bar = false
config.line_height = 1.2
config.window_close_confirmation = 'NeverPrompt'
-- config.freetype_load_target = "Light"
config.font = wezterm.font('Inconsolata Nerd Font', { weight = "Medium" })
config.font_size = 17
config.audible_bell = "Disabled"
return config
