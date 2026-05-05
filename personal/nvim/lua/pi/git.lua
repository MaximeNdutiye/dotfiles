local M = {}

function M.status(cwd)
  local output = vim.fn.systemlist({ "git", "-C", cwd, "status", "--porcelain" })
  if vim.v.shell_error ~= 0 then return {} end

  local changes = {}
  for _, line in ipairs(output) do
    if line ~= "" then
      local code = vim.fn.trim(line:sub(1, 2))
      local file = line:sub(4)
      local change_type = "modified"
      if code == "??" or code == "A" then
        change_type = "added"
      elseif code == "D" then
        change_type = "deleted"
      elseif code == "R" then
        change_type = "renamed"
      end
      table.insert(changes, { file = file, type = change_type, code = code })
    end
  end

  return changes
end

function M.diff(cwd, file_path)
  local output = vim.fn.system({ "git", "-C", cwd, "diff", "HEAD", "--", file_path })
  if output == "" then
    output = vim.fn.system({ "git", "-C", cwd, "diff", "--no-index", "/dev/null", file_path })
    if output == "" then output = "(new file)" end
  end
  return output
end

-- Open changes in a Telescope picker
function M.show_changes(cwd)
  local ok, telescope = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("[pi.nvim] Telescope not available", vim.log.levels.ERROR)
    return
  end

  local changes = M.status(cwd)
  if #changes == 0 then
    vim.notify("[pi.nvim] No changes", vim.log.levels.INFO)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  telescope.new({}, {
    prompt_title = "Pi Changes (" .. vim.fn.fnamemodify(cwd, ":~") .. ")",
    finder = finders.new_table({
      results = changes,
      entry_maker = function(change)
        local badge = change.type:sub(1, 1):upper()
        return {
          value = change,
          display = string.format("[%s] %s", badge, change.file),
          ordinal = change.file,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Diff",
      define_preview = function(self, entry)
        local diff_text = M.diff(cwd, entry.value.file)
        local diff_lines = vim.split(diff_text, "\n")
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, diff_lines)
        vim.bo[self.state.bufnr].filetype = "diff"
      end,
    }),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local file = cwd .. "/" .. selection.value.file
          vim.cmd("edit " .. vim.fn.fnameescape(file))
        end
      end)
      return true
    end,
  }):find()
end

return M
