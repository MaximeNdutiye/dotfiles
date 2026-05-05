local config = require("pi.config")
local state = require("pi.state")

local M = {}

local TOOL_ICONS = {
  bash = "⌘",
  read = "📄",
  write = "✏️",
  edit = "🔧",
  grep = "🔍",
  find = "📂",
  ls = "📁",
}

local ns_id = vim.api.nvim_create_namespace("pi_tools")

function M.format_tool_cmd(tool_name, args)
  if not args then return nil end
  if type(args) == "string" then
    local ok, decoded = pcall(vim.json.decode, args)
    if ok then args = decoded else return args end
  end
  if type(args) ~= "table" or vim.tbl_isempty(args) then return nil end

  if tool_name == "bash" and args.command then
    return "$ " .. args.command
  end
  if tool_name == "read" and args.path then
    local s = "read " .. args.path
    if args.offset then s = s .. " +" .. args.offset end
    return s
  end
  if tool_name == "write" and args.path then
    return "write → " .. args.path
  end
  if tool_name == "edit" and args.path then
    return "edit → " .. args.path
  end
  if tool_name == "grep" then
    return string.format('grep "%s" %s', args.pattern or "", args.path or "")
  end
  if tool_name == "find" then
    return string.format('find %s %s', args.path or ".", args.pattern and ('"' .. args.pattern .. '"') or "")
  end
  if tool_name == "ls" then
    return "ls " .. (args.path or ".")
  end

  -- Generic fallback
  local parts = {}
  for k, v in pairs(args) do
    local s = type(v) == "string" and v or vim.json.encode(v)
    if #s > 60 then s = s:sub(1, 57) .. "…" end
    table.insert(parts, k .. "=" .. s)
  end
  return table.concat(parts, "  ")
end

function M.render_tool_start(bufnr, tool_call_id, tool_name, args)
  local icon = TOOL_ICONS[tool_name] or "⚡"
  local cmd_str = M.format_tool_cmd(tool_name, args)

  local lines = {
    string.format("%s %s  ⟳ running", icon, tool_name),
  }
  if cmd_str then
    table.insert(lines, "  " .. cmd_str)
  end
  -- Fold marker for output (initially empty, will be filled on updates/end)
  table.insert(lines, "  ╶─── output ───╴ {{{")
  table.insert(lines, "  ╶─────────────╴ }}}")
  table.insert(lines, "")

  -- Append to buffer
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Store tool position info
  local tool_start = line_count -- 0-indexed start of the tool block
  state.tool_els[tool_call_id] = {
    line_start = tool_start,
    header_line = tool_start, -- 0-indexed
    output_start = tool_start + (#lines - 3), -- line after "output" marker
    output_end = tool_start + (#lines - 2), -- line of closing fold marker
    name = tool_name,
    args = args,
    status = "running",
    bufnr = bufnr,
  }

  return tool_start
end

function M.update_tool_streaming(bufnr, tool_call_id, partial_result, args)
  local tool = state.tool_els[tool_call_id]
  if not tool then return end

  -- Update args if we got new ones
  if args and (not tool.args or vim.tbl_isempty(tool.args)) then
    tool.args = args
  end

  -- Extract text from partial result
  local text = ""
  if partial_result and partial_result.content then
    for _, c in ipairs(partial_result.content) do
      if c.text then text = text .. c.text end
    end
  end
  if text == "" then return end

  -- Truncate for display
  local cfg = config.get()
  local output_lines = vim.split(text, "\n")
  if #output_lines > cfg.max_tool_output_lines then
    local truncated = {}
    for i = 1, cfg.max_tool_output_lines do
      truncated[i] = "  " .. output_lines[i]
    end
    table.insert(truncated, string.format("  … %d more lines", #output_lines - cfg.max_tool_output_lines))
    output_lines = truncated
  else
    for i, line in ipairs(output_lines) do
      output_lines[i] = "  " .. line
    end
  end

  -- Replace output section
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, tool.output_start, tool.output_end, false, output_lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Update end position
  tool.output_end = tool.output_start + #output_lines
end

function M.finish_tool(bufnr, tool_call_id, result, is_error, args)
  local tool = state.tool_els[tool_call_id]
  if not tool then return end

  -- Update args
  if args and (not tool.args or vim.tbl_isempty(tool.args)) then
    tool.args = args
  end

  -- Update header status
  local icon = TOOL_ICONS[tool.name] or "⚡"
  local status = is_error and "✗ failed" or "✓ done"
  local header = string.format("%s %s  %s", icon, tool.name, status)
  local cmd_str = M.format_tool_cmd(tool.name, tool.args)

  local header_lines = { header }
  if cmd_str then
    table.insert(header_lines, "  " .. cmd_str)
  end

  -- Extract result text
  local text = ""
  if result and result.content then
    for _, c in ipairs(result.content) do
      if c.text then text = text .. c.text end
    end
  end

  -- Build output lines
  local output_lines = {}
  if text ~= "" then
    local raw_lines = vim.split(text, "\n")
    local cfg = config.get()
    local max = cfg.max_tool_output_lines
    local display = #raw_lines > max and vim.list_slice(raw_lines, 1, max) or raw_lines
    for _, line in ipairs(display) do
      table.insert(output_lines, "  " .. line)
    end
    if #raw_lines > max then
      table.insert(output_lines, string.format("  … %d more lines", #raw_lines - max))
    end
  else
    table.insert(output_lines, "  (no output)")
  end

  -- Rebuild the entire tool block
  local all_lines = {}
  vim.list_extend(all_lines, header_lines)
  table.insert(all_lines, "  ╶─── output ───╴ {{{")
  vim.list_extend(all_lines, output_lines)
  table.insert(all_lines, "  ╶─────────────╴ }}}")
  table.insert(all_lines, "")

  -- Calculate the full tool block range
  local block_end = tool.output_end + 2 -- +1 for closing fold, +1 for blank line
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if block_end > line_count then block_end = line_count end

  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, tool.line_start, block_end, false, all_lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Clean up
  tool.status = is_error and "error" or "done"
  state.tool_els[tool_call_id] = nil
end

return M
