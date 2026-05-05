local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local BUILTIN_COMMANDS = {
  { name = "model", desc = "Switch model" },
  { name = "thinking", desc = "Set thinking level" },
  { name = "compact", desc = "Compact context" },
  { name = "new", desc = "New session" },
  { name = "session", desc = "Session info & stats" },
  { name = "name", desc = "Set session name" },
  { name = "export", desc = "Export to HTML" },
  { name = "copy", desc = "Copy last response" },
  { name = "help", desc = "Show all commands" },
}

function M.pick(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Pi Commands",
    finder = finders.new_table({
      results = BUILTIN_COMMANDS,
      entry_maker = function(cmd)
        return {
          value = cmd,
          display = "/" .. cmd.name .. "  " .. cmd.desc,
          ordinal = cmd.name .. " " .. cmd.desc,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local input_mod = require("pi.ui.input")
          input_mod.handle_slash_command("/" .. selection.value.name)
        end
      end)
      return true
    end,
  }):find()
end

return M
