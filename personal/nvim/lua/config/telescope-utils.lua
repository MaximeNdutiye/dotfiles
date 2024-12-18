local telescope_global_state = require "telescope.state"
local conf = require("telescope.config").values
local notify = require "notify"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"

local telescope_utils = {}

-- Read the JSON data from the file
function telescope_utils.toggle_telescope_with_log_file_code_locations()
  local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false), "\n")

  -- Parse the JSON data
  local data = vim.json.decode(content)

  -- Table to store unique filepaths
  local filepaths = {}

  for _, item in ipairs(data) do
    if item["code.filepath"] ~= nil then
      local relative_path = string.gsub(item["code.filepath"], "/app/areas/core/shopify", "")
      local line_no = item["code.lineno"]
      local new_path = "/Users/maximendutiye/src/github.com/Shopify/shopify/areas/core/shopify" .. relative_path

      local telescope_entry = {
        path = new_path,
        value = relative_path,
        display = relative_path .. ":" .. line_no .. ":1",
        ordinal = relative_path,
        lnum = line_no,
      }

      table.insert(filepaths, telescope_entry)
    end
  end

  vim.print(vim.inspect(filepaths))

  if #filepaths == 0 then notify "No Content" end

  -- return {}
  return filepaths
  -- Write the filepaths to the quickfix format file
  -- local outfile = io.open("/Users/maximendutiye/Downloads/filepaths.qf", "w")

  -- if(outfile == nil) then return end;

  -- for filepath, lineno in pairs(filepaths) do
  --   outfile:write(filepath .. lineno .. ":1 File path\n")
  -- end
  --
  -- outfile:write(vim.inspect(filepaths))
  -- outfile:close()
end

function telescope_utils.is_telescope_open() return next(telescope_global_state.get_existing_prompt_bufnrs()) ~= nil end

-- this is a list of objects like this
-- [{
--   path = new_path,
--   value = relative_path,
--   display = relative_path,
--   ordinal = relative_path,
--   lnum = line_no,
-- }]
function telescope_utils.toggle_telescope(file_paths)
  local finder = require("telescope.finders").new_table {
    results = file_paths,
    entry_maker = function(entry) return entry end,
  }

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Telescope",
      finder = finder,
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

function telescope_utils.open_telescope_with_list(list, prompt_title)
  prompt_title = prompt_title or "Select an item"

  local selected_item = nil

  pickers
    .new({}, {
      prompt_title = prompt_title,
      finder = finders.new_table {
        results = list,
      },
      sorter = conf.generic_sorter {},
      -- attach_mappings = function(prompt_bufnr, map)
      --   actions.select_default:replace(function()
      --     local selection = action_state.get_selected_entry()
      --     actions.close(prompt_bufnr)
      --     selected_item = selection.value
      --   end)
      --   return true
      -- end,
    })
    :find()

  -- Wait for the selection to be made
  vim.wait(10000, function() return selected_item ~= nil end, 100)

  return selected_item
end

return telescope_utils
