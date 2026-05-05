local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

function M.pick(opts)
  opts = opts or {}
  local pi = require("pi")

  pi.run_async(function()
    local agent = require("pi.agent")
    local models_res = agent.rpc_call_async({ type = "get_available_models" })
    local state_res = agent.rpc_call_async({ type = "get_state" })

    if not models_res or not models_res.success then
      vim.notify("[pi.nvim] Failed to get models", vim.log.levels.ERROR)
      return
    end

    local current_id = state_res and state_res.data and state_res.data.model and state_res.data.model.id
    local models = models_res.data.models or {}

    vim.schedule(function()
      pickers.new(opts, {
        prompt_title = "Pi Models",
        finder = finders.new_table({
          results = models,
          entry_maker = function(model)
            local is_current = model.id == current_id
            local prefix = is_current and "● " or "  "
            return {
              value = model,
              display = prefix .. (model.name or model.id) .. "  " .. (model.provider or ""),
              ordinal = (model.name or "") .. " " .. model.id .. " " .. (model.provider or ""),
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              local model = selection.value
              pi.run_async(function()
                local res = agent.rpc_call_async({
                  type = "set_model",
                  provider = model.provider,
                  modelId = model.id,
                })
                vim.schedule(function()
                  if res and res.success then
                    local name = model.name or model.id
                    vim.notify("[pi.nvim] Model → " .. name)
                    local st = require("pi.state")
                    local a = st.get_active_agent()
                    if a then a.model = name end
                  else
                    vim.notify("[pi.nvim] Failed to set model", vim.log.levels.ERROR)
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
