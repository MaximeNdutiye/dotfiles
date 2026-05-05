local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local sessions_mod = require("pi.sessions")

local M = {}

function M.pick(opts)
  opts = opts or {}

  local sessions = sessions_mod.list()

  if #sessions == 0 then
    vim.notify("[pi.nvim] No sessions found", vim.log.levels.INFO)
    return
  end

  pickers.new(opts, {
    prompt_title = "Pi Sessions",
    finder = finders.new_table({
      results = sessions,
      entry_maker = function(session)
        local title = session.name or session.first_message or "(empty)"
        local short_cwd = vim.fn.fnamemodify(session.cwd, ":~")
        local display = string.format(
          "%s  %s · %d msgs · %s",
          title, short_cwd, session.message_count, session.time_ago
        )
        return {
          value = session,
          display = display,
          ordinal = (session.name or "") .. " " .. session.first_message .. " " .. session.cwd,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = previewers.new_buffer_previewer({
      title = "Session Preview",
      define_preview = function(self, entry)
        local session = entry.value
        local ok, content = pcall(vim.fn.readfile, session.file_path, "", 50)
        if not ok or not content then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Could not read session file" })
          return
        end

        local preview_lines = {
          "# " .. (session.name or "Session"),
          "CWD: " .. session.cwd,
          "Messages: " .. session.message_count,
          "Last modified: " .. session.time_ago,
          "",
          "---",
          "",
        }

        for _, line in ipairs(content) do
          if line:match("%S") then
            local decode_ok, entry_data = pcall(vim.json.decode, line)
            if decode_ok and entry_data and entry_data.message then
              local role = entry_data.message.role or "?"
              local c = entry_data.message.content
              local text = ""
              if type(c) == "string" then
                text = c:sub(1, 200)
              elseif type(c) == "table" then
                for _, part in ipairs(c) do
                  if part.text then
                    text = text .. part.text:sub(1, 200)
                    break
                  end
                end
              end
              if text ~= "" then
                table.insert(preview_lines, string.format("**%s**: %s", role, text))
                table.insert(preview_lines, "")
              end
            end
          end
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
      end,
    }),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local pi = require("pi")
          pi.connect_to_session(selection.value.cwd, selection.value.file_path)
        end
      end)
      return true
    end,
  }):find()
end

return M
