local notify = require "notify"

local dev_test_runner = {}

_G.source_code_file_paths = {}

-- I need to have this run async, when the buffer first opens
function dev_test_runner.find_first_matching_file()
  _G.source_code_file_path = vim.fn.expand "%:t"
  _G.matching_test_file_path = nil

  local file_without_ext = vim.fn.fnamemodify(source_code_file_path, ":r")

  local file_with_ext = file_without_ext .. "_test.rb"
  local search_pattern = file_with_ext

  local command = string.format("find . -name '%s' -print -quit", search_pattern)

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and data[1] and data[1] ~= "" then
        local file_path = data[1]
        _G.matching_test_file_path = file_path
        _G.source_code_file_paths[source_code_file_path] = file_path
      else
        _G.matching_test_file_path = nil
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        _G.matching_test_file_path = nil
        vim.schedule(function() notify("Error searching for test file", vim.log.levels.ERROR) end)
      end
    end,
  })
end

function dev_test_runner.open_test_file()
  local source_file = vim.fn.expand "%:t"
  local file_extension = vim.fn.expand "%:e"

  if file_extension ~= "rb" then
    vim.schedule(function() notify("Not a Ruby file", vim.log.levels.WARN) end)
    return
  end

  if string.find(source_file, "test") then
    vim.schedule(function() notify("Already in a test file", vim.log.levels.WARN) end)
    return
  end

  local test_file = _G.source_code_file_paths[source_file]
  if test_file == nil then
    vim.schedule(function() notify("No matching test file found", vim.log.levels.WARN) end)
    return
  end

  local test_file_fixed = string.sub(test_file, 3, string.len(test_file))
  vim.schedule(function()
    vim.cmd("edit " .. test_file_fixed)
    notify("🧪 " .. test_file, vim.log.levels.INFO)
  end)
end

return dev_test_runner
