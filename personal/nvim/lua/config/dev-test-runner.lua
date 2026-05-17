local notify = vim.notify

local M = {}

-- Configuration
M.auto_find_first_matching_file = true
M.search_results = {}

-- Helper functions
local function warn(message)
  vim.schedule(function() notify(message, vim.log.levels.WARN) end)
end

-- Walk up from a directory to find the nearest component root.
-- A component root is a directory that contains (app/ or lib/) and test/,
-- or contains a Gemfile. This correctly scopes searches within monorepos
-- like world (src/areas/<area>/<component>/ or components/<name>/).
local function find_component_root(start_dir)
  local dir = start_dir
  local home = vim.env.HOME or ""

  while dir and dir ~= "/" and dir ~= home do
    local has_test = vim.fn.isdirectory(dir .. "/test") == 1
    local has_app = vim.fn.isdirectory(dir .. "/app") == 1
    local has_lib = vim.fn.isdirectory(dir .. "/lib") == 1
    local has_gemfile = vim.fn.filereadable(dir .. "/Gemfile") == 1

    if has_test and (has_app or has_lib) then return dir end
    if has_gemfile then return dir end

    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return nil
end

local function find_best_match(target_path, path_list, file_name)
  local target_without_file = target_path:gsub(file_name .. "$", "")
  local best_match, max_matches = nil, 0

  for _, path in ipairs(path_list) do
    local candidate = path:gsub(file_name .. "$", "")
    local match_count = 0

    -- Compare path characters from the end of both strings
    local ti, ci = #target_without_file, #candidate
    while ti > 0 and ci > 0 do
      if target_without_file:sub(ti, ti) == candidate:sub(ci, ci) then
        match_count = match_count + 1
      end
      ti = ti - 1
      ci = ci - 1
    end

    if match_count > max_matches then
      max_matches, best_match = match_count, path
    end
  end

  return best_match
end

-- Core functions
local function find_matching_file(source_file, search_file)
  local source_dir = vim.fn.fnamemodify(source_file, ":h")
  local search_root = find_component_root(source_dir) or vim.fn.getcwd()
  local command = string.format("find %s -name '%s'", vim.fn.shellescape(search_root), search_file)

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        -- Filter out empty strings from data
        local paths = vim.tbl_filter(function(p) return p ~= "" end, data)
        if #paths == 0 then return end

        local best_match = find_best_match(source_file, paths, search_file)
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

  if not other_file then return warn "No matches" end

  vim.schedule(function() vim.cmd("edit " .. vim.fn.fnameescape(other_file)) end)
end

return M
