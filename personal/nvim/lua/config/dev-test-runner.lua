local notify = require "notify"

local M = {}

-- Configuration
M.auto_find_first_matching_file = true
M.search_results = {}

-- Helper functions
local function warn(message)
  vim.schedule(function() notify(message, vim.log.levels.WARN) end)
end

local function find_best_match(target_path, path_list, file_name)
  local target_without_file = target_path:gsub(file_name, "")
  local target_length = #target_without_file
  local best_match, max_matches = nil, 0

  for _, path in ipairs(path_list) do
    local path_without_file = path:gsub(file_name, "")
    local path_length = #path_without_file
    local match_count = 0

    for i = math.min(target_length, path_length), 1, -1 do
      if target_without_file:sub(i, i) == path_without_file:sub(i, i) then match_count = match_count + 1 end
    end

    if match_count > max_matches then
      max_matches, best_match = match_count, path
    end
  end

  return best_match
end

-- Core functions
local function find_matching_file(source_file, search_file)
  local command = string.format("find . -name '%s'", search_file)

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        local best_match = find_best_match(source_file, data, search_file)
        M.search_results[source_file] = best_match
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then warn "Error searching for matching file" end
    end,
  })
end

function M.find_matching_test_file()
  local source_file_path = vim.fn.expand "%:p"
  local file_without_ext = vim.fn.fnamemodify(vim.fn.expand "%:t", ":r")
  local test_file_pattern = file_without_ext .. "_test.rb"

  find_matching_file(source_file_path, test_file_pattern)
end

function M.find_matching_source_file()
  local test_file_path = vim.fn.expand "%:p"
  local file_without_ext = vim.fn.fnamemodify(vim.fn.expand "%:t", ":r")
  local source_file_name = file_without_ext:gsub("_test$", "") .. ".rb"

  find_matching_file(test_file_path, source_file_name)
end

-- Autocommand function
function M.on_autocommand()
  if not M.auto_find_first_matching_file then return end

  local file_extension = vim.fn.expand "%:e"
  if file_extension ~= "rb" then return end

  local current_file_name = vim.fn.expand "%:t"
  if string.find(current_file_name, "test") then
    M.find_matching_source_file()
  else
    M.find_matching_test_file()
  end
end

-- User-facing function
function M.open_test_or_source_file()
  local current_file = vim.fn.expand "%:p"
  local other_file = M.search_results[current_file]

  if not other_file then return warn "â No matches" end

  local file_path = other_file:gsub("^%./", "") -- Remove leading './' from the path

  vim.schedule(function() vim.cmd("edit " .. file_path) end)
end

return M
