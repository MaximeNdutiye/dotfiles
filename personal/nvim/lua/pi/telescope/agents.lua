local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local agent_mod = require("pi.agent")

local M = {}

function M.pick(opts)
  opts = opts or {}

  local agents = agent_mod.list()

  if #agents == 0 then
    vim.notify("[pi.nvim] No running agents", vim.log.levels.INFO)
    return
  end

  pickers.new(opts, {
    prompt_title = "Pi Agents",
    finder = finders.new_table({
      results = agents,
      entry_maker = function(a)
        local prefix = a.is_active and "● " or "  "
        local short_cwd = vim.fn.fnamemodify(a.cwd, ":~")
        local display = string.format(
          "%s%s  %s  [%s]",
          prefix, a.name or short_cwd, a.model or "", a.state or ""
        )
        return {
          value = a,
          display = display,
          ordinal = (a.name or "") .. " " .. a.cwd .. " " .. (a.model or ""),
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local pi = require("pi")
          pi.switch_agent(selection.value.id)
        end
      end)
      return true
    end,
  }):find()
end

return M
