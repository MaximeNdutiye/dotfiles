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

--- APPEARANCE ---
-- latte = {
-- 	rosewater = "#dc8a78",
-- 	flamingo = "#dd7878",
-- 	pink = "#ea76cb",
-- 	mauve = "#8839ef",
-- 	red = "#d20f39",
-- 	maroon = "#e64553",
-- 	peach = "#fe640b",
-- 	yellow = "#df8e1d",
-- 	green = "#40a02b",
-- 	teal = "#179299",
-- 	sky = "#04a5e5",
-- 	sapphire = "#209fb5",
-- 	blue = "#1e66f5",
-- 	lavender = "#7287fd",
-- 	text = "#4c4f69",
-- 	subtext1 = "#5c5f77",
-- 	subtext0 = "#6c6f85",
-- 	overlay2 = "#7c7f93",
-- 	overlay1 = "#8c8fa1",
-- 	overlay0 = "#9ca0b0",
-- 	surface2 = "#acb0be",
-- 	surface1 = "#bcc0cc",
-- 	surface0 = "#ccd0da",
-- 	crust = "#dce0e8",
-- 	mantle = "#e6e9ef",
-- 	base = "#eff1f5",
-- },

config.window_frame = {
	-- The font used in the tab bar.
	-- Roboto Bold is the default; this font is bundled
	-- with wezterm.
	-- Whatever font is selected here, it will have the
	-- main font setting appended to it to pick up any
	-- fallback fonts you may have used there.
	-- font = wezterm.font({ family = "Roboto", weight = "Bold" }),

	-- The size of the font in the tab bar.
	-- Default to 10.0 on Windows but 12.0 on other systems
	-- font_size = 12.0,

	-- The overall background color of the tab bar when
	-- the window is focused
	-- active_titlebar_bg = "#d9dbde",

	-- The overall background color of the tab bar when
	-- the window is not focused
	-- inactive_titlebar_bg = "#bcc0cc",
}

config.colors = {
	-- tab_bar = {
	-- 	-- The color of the inactive tab bar edge/divider
	-- 	inactive_tab_edge = "#eff1f5",
	-- 	active_tab = {
	-- 		-- The color of the background area for the tab
	-- 		bg_color = "#eff1f5",
	-- 		-- The color of the text for the tab
	-- 		fg_color = "text",
	--
	-- 		-- Specify whether you want "Half", "Normal" or "Bold" intensity for the
	-- 		-- label shown for this tab.
	-- 		-- The default is "Normal"
	-- 		intensity = "Normal",
	--
	-- 		-- Specify whether you want "None", "Single" or "Double" underline for
	-- 		-- label shown for this tab.
	-- 		-- The default is "None"
	-- 		underline = "None",
	--
	-- 		-- Specify whether you want the text to be italic (true) or not (false)
	-- 		-- for this tab.  The default is false.
	-- 		italic = false,
	--
	-- 		-- Specify whether you want the text to be rendered with strikethrough (true)
	-- 		-- or not for this tab.  The default is false.
	-- 		strikethrough = false,
	-- 	},
	-- 	inactive_tab_hsb = {
	-- 		-- bg_color = "#9ca0b0",
	-- 		-- fg_color = "#eff1f5",
	-- 		-- italic = true,
	-- 		brightness = 0.8,
	-- 	},
		-- The new tab button that let you create new tabs
		-- 	new_tab = {
		-- 		bg_color = "#9ca0b0",
		-- 		fg_color = "#ccd0da",
		--
		-- 		-- The same options that were listed under the `active_tab` section above
		-- 		-- can also be used for `new_tab`.
		-- 	},
		-- 	inactive_tab_hover = {
		-- 		bg_color = "#e6e9ef",
		-- 		fg_color = "text",
		-- 	},
		-- 	-- You can configure some alternate styling when the mouse pointer
		-- 	-- moves over the new tab button
		-- 	new_tab_hover = {
		-- 		bg_color = "#9ca0b0",
		-- 		fg_color = "#ccd0da",
		-- 	},
	-- },
}

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

------------ KEY MAPPINGS ------------

-- timeout_milliseconds defaults to 1000 and can be omitted
-- leader is <C-a>
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
	{
		key = "a",
		mods = "LEADER|CTRL",
		action = act.SendKey({ key = "a", mods = "CTRL" }),
	},
	-- ACTIVATE COPY MODE
	{
		key = "[",
		mods = "LEADER",
		action = wezterm.action.ActivateCopyMode,
	},
	-- RENAME TAB
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
	-- PANES SPLITS
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
	-- see skip_close_confirmation_for_processes_named
	{
		key = "x",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	-- PANE SWITCH PANE DIRECTION
	-- {
	-- 	key = "h",
	-- 	mods = "LEADER",
	-- 	action = act.ActivatePaneDirection("Left"),
	-- },
	-- {
	-- 	key = "l",
	-- 	mods = "LEADER",
	-- 	action = act.ActivatePaneDirection("Right"),
	-- },
	-- {
	-- 	key = "k",
	-- 	mods = "LEADER",
	-- 	action = act.ActivatePaneDirection("Up"),
	-- },
	-- {
	-- 	key = "j",
	-- 	mods = "LEADER",
	-- 	action = act.ActivatePaneDirection("Down"),
	-- },
	-- PANE SIZING
	-- {
	-- 	key = "h",
	-- 	mods = "CTRL",
	-- 	action = act.AdjustPaneSize({ "Left", 5 }),
	-- },
	-- {
	-- 	key = "l",
	-- 	mods = "CTRL",
	-- 	action = act.AdjustPaneSize({ "Right", 5 }),
	-- },
	-- {
	-- 	key = "k",
	-- 	mods = "CTRL",
	-- 	action = act.AdjustPaneSize({ "Up", 5 }),
	-- },
	-- {
	-- 	key = "j",
	-- 	mods = "CTRL",
	-- 	action = act.AdjustPaneSize({ "Down", 5 }),
	-- },
	-- PANE ZOOM
	{
		key = "z",
		mods = "LEADER",
		action = wezterm.action.TogglePaneZoomState,
	},
}

-- SMART SPLITS
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
