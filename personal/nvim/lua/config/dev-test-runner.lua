local notify = require "notify"

local DevTestRunner = {}

local function warn(message)
  vim.schedule(function() notify(message, vim.log.levels.WARN) end)
end

-- We run the auto command on BufReadPost
DevTestRunner.auto_find_first_matching_file = true
DevTestRunner.search_results = {}

local function find_best_match(target_path, path_list, file_name)
  local target_without_file = target_path:gsub(file_name, "")
  local target_length = #target_without_file
  local best_match = nil
  local max_matches = 0

  for _, path in ipairs(path_list) do
    local path_without_file = path:gsub(file_name, "")
    local path_length = #path_without_file
    local match_count = 0

    -- Count matching characters
    for i = math.min(target_length, path_length), 1, -1 do
      if target_without_file:sub(i, i) == path_without_file:sub(i, i) then match_count = match_count + 1 end
    end

    -- Update best match if this one has more matches
    if match_count > max_matches then
      max_matches = match_count
      best_match = path
    end
  end

  return best_match
end

function DevTestRunner.get_nearest_test_path()
  local path = vim.fn.expand "%:p:h"
  while path ~= "/" do
    if vim.fn.isdirectory(path .. "/test") == 1 then return path .. "/test" end
    path = vim.fn.fnamemodify(path, ":h")
  end
end

function DevTestRunner.get_path_without_test(path)
  local test_index = string.find(path, "/test/")
  if test_index then return string.sub(path, 1, test_index) end
end

function DevTestRunner.find_matching_test_file()
  local source_file_path = vim.fn.expand "%:p"
  local file_without_ext = vim.fn.fnamemodify(vim.fn.expand "%:t", ":r")
  local test_file_pattern = file_without_ext .. "_test.rb"
  local test_path = DevTestRunner.get_nearest_test_path()
  local command = string.format("find '%s' -name '%s'", test_path, test_file_pattern)

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        local best_match = find_best_match(source_file_path, data, test_file_pattern)
        DevTestRunner.search_results[source_file_path] = best_match
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then warn "Error searching for test file" end
    end,
  })
end

function DevTestRunner.find_matching_source_file()
  local test_file_path = vim.fn.expand "%:p"
  local file_without_ext = vim.fn.fnamemodify(vim.fn.expand "%:t", ":r")
  local source_file_name = file_without_ext:gsub("_test$", "") .. ".rb"
  local search_path = DevTestRunner.get_path_without_test(vim.fn.expand "%:p")
  local command = string.format("find '%s' -name '%s'", search_path, source_file_name)

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        local best_match = find_best_match(test_file_path, data, source_file_name)
        DevTestRunner.search_results[test_file_path] = best_match
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then warn "Error searching for source file" end
    end,
  })
end

function DevTestRunner.on_autocommand()
  if DevTestRunner.auto_find_first_matching_file ~= true then return end

  local file_extension = vim.fn.expand "%:e"
  if file_extension ~= "rb" then return end

  local current_file_name = vim.fn.expand "%:t"
  if string.find(current_file_name, "test") then
    DevTestRunner.find_matching_source_file()
  else
    DevTestRunner.find_matching_test_file()
  end
end

function DevTestRunner.open_test_or_source_file()
  local current_file = vim.fn.expand "%:p"
  local other_file = DevTestRunner.search_results[current_file]

  if other_file == nil then return warn "No matching %s file found" end

  -- Remove leading './' from the path
  local file_path = other_file:gsub("^%./", "")

  vim.schedule(function()
    -- notify(string.format("🧪 Opening"), vim.log.levels.INFO)
    vim.cmd("edit " .. file_path)
  end)
end

return DevTestRunner
