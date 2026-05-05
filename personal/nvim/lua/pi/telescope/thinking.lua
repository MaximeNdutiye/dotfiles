local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local LEVELS = { "off", "minimal", "low", "medium", "high" }

function M.pick(opts)
  opts = opts or {}
  local pi = require("pi")

  pi.run_async(function()
    local agent = require("pi.agent")
    local state_res = agent.rpc_call_async({ type = "get_state" })
    local current = state_res and state_res.data and state_res.data.thinkingLevel or "off"

    vim.schedule(function()
      pickers.new(opts, {
        prompt_title = "Pi Thinking Level",
        finder = finders.new_table({
          results = LEVELS,
          entry_maker = function(level)
            local is_current = level == current
            local prefix = is_current and "● " or "  "
            return {
              value = level,
              display = prefix .. level,
              ordinal = level,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              pi.run_async(function()
                local res = agent.rpc_call_async({
                  type = "set_thinking_level",
                  level = selection.value,
                })
                vim.schedule(function()
                  if res and res.success then
                    vim.notify("[pi.nvim] Thinking → " .. selection.value)
                  else
                    vim.notify("[pi.nvim] Failed to set thinking level", vim.log.levels.ERROR)
                  end
                end)
              end)
            end
          end)
          return true
        end,
      }):find()
    end)
  end)
end

return M
