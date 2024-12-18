-- Pull in the wezterm API
local wezterm = require("wezterm")

local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

-- This will hold the configuration.
local config = wezterm.config_builder()
local act = wezterm.action

config.switch_to_last_active_tab_when_closing_tab = true
config.use_fancy_tab_bar = true
config.pane_focus_follows_mouse = true
config.tab_max_width = 32
config.scrollback_lines = 5000
config.underline_thickness = 1
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

-- https://wezfurlong.org/wezterm/config/lua/keyassignment/index.html

------------ KEY MAPPINGS ------------
-- leader is <C-a>
-- timeout_milliseconds defaults to 1000 and can be omitted
-- C-a will wait for keypresses for 1s
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
	{
		key = "a",
		mods = "LEADER|CTRL",
		action = act.SendKey({ key = "a", mods = "CTRL" }),
	},
	-- Copy mode 
	{
		key = "[",
		mods = "LEADER",
		action = wezterm.action.ActivateCopyMode,
	},
	-- Tab
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	-- Panes
	{
		key = "\\",
		mods = "LEADER",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "-",
		mods = "LEADER",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "x",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	-- Tab nav
	{ key = "t", mods = "LEADER", action = wezterm.action.ShowTabNavigator },
	-- Zoom
	{
		key = "z",
		mods = "LEADER",
		action = wezterm.action.TogglePaneZoomState,
	},
}

-- Smat splits
smart_splits.apply_to_config(config, {
	direction_keys = {
		move = { "h", "j", "k", "l" },
		resize = { "h", "j", "k", "l" },
	},
	-- modifier keys to combine with direction_keys
	modifiers = {
		move = "CTRL",
		resize = "ALT",
	},
})

-- and finally, return the configuration to wezterm
return config
