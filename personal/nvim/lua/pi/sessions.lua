local config = require("pi.config")

local M = {}

-- Decode session directory name to path
-- Strip leading dashes, replace - with /, prepend /
local function decode_dir_name(dir)
  local s = dir:gsub("^-+", ""):gsub("-+$", ""):gsub("-", "/")
  return "/" .. s
end

-- Format time ago string
local function time_ago(timestamp_ms)
  local now = os.time() * 1000
  local diff = now - timestamp_ms
  local seconds = math.floor(diff / 1000)
  local minutes = math.floor(seconds / 60)
  local hours = math.floor(minutes / 60)
  local days = math.floor(hours / 24)

  if days > 0 then return days .. "d ago" end
  if hours > 0 then return hours .. "h ago" end
  if minutes > 0 then return minutes .. "m ago" end
  return "just now"
end

function M.list()
  local cfg = config.get()
  local session_dir = cfg.session_dir

  if vim.fn.isdirectory(session_dir) == 0 then
    return {}
  end

  local sessions = {}
  local dirs = vim.fn.readdir(session_dir)

  -- Take last 20 dirs (sorted by name which encodes path)
  local start_idx = math.max(1, #dirs - 19)
  for i = start_idx, #dirs do
    local dir = dirs[i]
    local dir_path = session_dir .. "/" .. dir
    local stat = vim.loop.fs_stat(dir_path)
    if stat and stat.type == "directory" then
      local files = vim.fn.readdir(dir_path)
      local jsonl_files = vim.tbl_filter(function(f)
        return f:match("%.jsonl$")
      end, files)

      -- Take last 10 jsonl files
      local file_start = math.max(1, #jsonl_files - 9)
      for j = file_start, #jsonl_files do
        local file = jsonl_files[j]
        local file_path = dir_path .. "/" .. file
        local fstat = vim.loop.fs_stat(file_path)
        if fstat then
          local session = M.parse_session_file(file_path, dir, fstat.mtime.sec * 1000)
          if session then
            table.insert(sessions, session)
          end
        end
      end
    end
  end

  -- Sort by last modified descending
  table.sort(sessions, function(a, b)
    return a.last_modified > b.last_modified
  end)

  return sessions
end

function M.parse_session_file(file_path, dir_name, mtime_ms)
  local ok, content = pcall(vim.fn.readfile, file_path, "", 30) -- Read first 30 lines
  if not ok or not content then return nil end

  local name = nil
  local first_message = nil
  local cwd = nil
  local message_count = 0

  for _, line in ipairs(content) do
    if line:match("%S") then
      local decode_ok, entry = pcall(vim.json.decode, line)
      if decode_ok and entry then
        if entry.type == "session" or entry.type == "header" then
          cwd = entry.cwd
          name = entry.name
        end
        if entry.message then
          message_count = message_count + 1
          if entry.message.role == "user" and not first_message then
            local c = entry.message.content
            if type(c) == "string" then
              first_message = c:sub(1, 120)
            elseif type(c) == "table" and c[1] and c[1].text then
              first_message = c[1].text:sub(1, 120)
            end
          end
        end
      end
    end
  end

  return {
    file_path = file_path,
    name = name,
    first_message = first_message or "(empty)",
    cwd = cwd or decode_dir_name(dir_name),
    message_count = message_count,
    last_modified = mtime_ms,
    time_ago = time_ago(mtime_ms),
  }
end

return M
