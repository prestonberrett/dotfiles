-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.font = wezterm.font("ZedMono NFM Extd", { weight = "Bold" })
config.font_size = 18.0
config.line_height = 1.2

-- For example, changing the color scheme:
config.color_scheme = "Shades of Purple (base16)"
config.scrollback_lines = 15000

config.default_cwd = "c:/dev"
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBar"

config.window_padding = {
  left = 5,
  right = 5,
  top = 5,
  bottom = 5,
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  -- For command prompt
  -- config.default_prog =
  --   { 'cmd.exe', '/s', '/k', 'C:/Users/rpb003/.config/clink/clink_x64.exe', 'inject', '-q' }
  -- For Powershell 7
  config.default_prog = { "pwsh.exe" }
end

config.keys = {
  -- this will create a new split and run the top command
  {
    key = "%",
    mods = "CTRL|SHIFT|ALT",
    action = wezterm.action.SplitPane({
      direction = "Left",
      command = { args = { "pwsh.exe" } },
      size = { Percent = 50 },
    }),
  },
  -- Cycle to the next pane
  {
    key = "RightArrow",
    mods = "CTRL|WIN",
    action = wezterm.action({
      ActivatePaneDirection = "Next",
    }),
  },
  -- Cycle to the previous pane
  {
    key = "LeftArrow",
    mods = "CTRL|WIN",
    action = wezterm.action({
      ActivatePaneDirection = "Prev",
    }),
  },
}

config.mouse_bindings = {
  {
    event = { Down = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor("Line"),
  },
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ""
      if has_selection then
        window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.PasteFrom("Clipboard"), pane)
      end
    end),
  },
}

-- and finally, return the configuration to wezterm
return config
