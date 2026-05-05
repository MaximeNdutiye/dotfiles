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

-- Override low-contrast colors in light mode
if wezterm.gui.get_appearance():find("Light") then
	config.colors = {
		ansi = {
			"#4c4f69", -- black (was too light)
			"#d20f39", -- red (default)
			"#40a02b", -- green (default)
			"#986a1d", -- yellow (darkened)
			"#1e66f5", -- blue (default)
			"#8839ef", -- magenta (default)
			"#179299", -- cyan (default)
			"#5c5f77", -- white (darkened)
		},
		brights = {
			"#4c4f69", -- bright black
			"#d20f39", -- bright red
			"#40a02b", -- bright green
			"#85710a", -- bright yellow (darkened)
			"#1e66f5", -- bright blue
			"#8839ef", -- bright magenta
			"#179299", -- bright cyan
			"#5c5f77", -- bright white (darkened)
		},
	}
end

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

	-- ============================================================
	-- Workspaces (cmux-parity)
	-- ============================================================

	-- LEADER s → fuzzy workspace picker (built-in launcher)
	{
		key = "s",
		mods = "LEADER",
		action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
	},

	-- LEADER S → create / switch to a workspace by typing its name
	{
		key = "S",
		mods = "LEADER|SHIFT",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter workspace name (will create or switch): " },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line and line ~= "" then
					window:perform_action(
						act.SwitchToWorkspace({ name = line }),
						pane
					)
				end
			end),
		}),
	},

	-- LEADER ] / [ → cycle to next/prev workspace
	{ key = "]", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
	{ key = "[", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },

	-- LEADER , → rename current workspace (replaces tab rename above; pick whichever you prefer)
	-- We keep the existing LEADER , for tab rename. Use LEADER R to rename workspace instead.
	{
		key = "R",
		mods = "LEADER|SHIFT",
		action = act.PromptInputLine({
			description = "Rename workspace to: ",
			action = wezterm.action_callback(function(_, _, line)
				if line and line ~= "" then wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line) end
			end),
		}),
	},

	-- Cmd+1–9 → jump to the Nth workspace (mirrors cmux Cmd+1–8)
	-- These are filled in dynamically below so we can list workspaces sorted by name.
}

-- Generate Cmd+1..Cmd+9 → nth workspace (cmux-style direct jumps).
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CMD",
		action = wezterm.action_callback(function(window, pane)
			local names = {}
			for _, ws in ipairs(wezterm.mux.get_workspace_names()) do
				table.insert(names, ws)
			end
			table.sort(names)
			local target = names[i]
			if target then
				window:perform_action(act.SwitchToWorkspace({ name = target }), pane)
			end
		end),
	})
end

-- Show the current workspace in the right side of the status bar.
wezterm.on("update-right-status", function(window, _)
	local ws = window:active_workspace()
	local n = #wezterm.mux.get_workspace_names()
	window:set_right_status(wezterm.format({
		{ Foreground = { AnsiColor = "Aqua" } },
		{ Text = " \u{f0c0} " .. ws .. " (" .. n .. ") " },
	}))
end)

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
