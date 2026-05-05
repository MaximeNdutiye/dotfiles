local state = require("pi.state")
local layout = require("pi.ui.layout")

local M = {}

-- Create an input buffer for prompts
function M.create_buffer(agent_id)
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].filetype = "piinput"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buflisted = false

  vim.api.nvim_buf_set_name(bufnr, "pi://input-" .. agent_id)

  -- Set up keymaps
  M.setup_keymaps(bufnr)

  return bufnr
end

function M.setup_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- <CR> in normal mode sends the prompt
  vim.keymap.set("n", "<CR>", function()
    M.send_prompt(bufnr)
  end, opts)

  -- <C-s> in insert mode sends the prompt
  vim.keymap.set("i", "<C-s>", function()
    vim.cmd("stopinsert")
    M.send_prompt(bufnr)
  end, opts)

  -- <C-c> abort streaming
  vim.keymap.set("n", "<C-c>", function()
    local pi = require("pi")
    pi.abort()
  end, opts)

  -- Escape in insert mode goes to normal mode, in normal mode focuses chat
  vim.keymap.set("n", "<Esc>", function()
    layout.focus_chat()
  end, opts)
end

function M.send_prompt(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = vim.fn.trim(table.concat(lines, "\n"))

  if text == "" then return end
  if not state.active_agent_id then
    vim.notify("[pi.nvim] No active agent", vim.log.levels.WARN)
    return
  end

  -- Clear input buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })

  -- Handle slash commands
  if text:sub(1, 1) == "/" then
    M.handle_slash_command(text)
    return
  end

  -- Send prompt
  local pi = require("pi")
  pi.send_prompt(text)
end

function M.handle_slash_command(text)
  local space_idx = text:find(" ")
  local name = space_idx and text:sub(1, space_idx - 1) or text
  local args = space_idx and vim.fn.trim(text:sub(space_idx + 1)) or ""

  local pi = require("pi")

  if name == "/model" then
    pi.cmd_model()
  elseif name == "/thinking" then
    pi.cmd_thinking()
  elseif name == "/compact" then
    pi.cmd_compact(args)
  elseif name == "/new" then
    pi.cmd_new()
  elseif name == "/session" or name == "/stats" then
    pi.cmd_session()
  elseif name == "/name" then
    pi.cmd_name(args)
  elseif name == "/help" then
    pi.cmd_help()
  elseif name == "/export" then
    pi.cmd_export()
  elseif name == "/copy" then
    pi.cmd_copy()
  else
    -- Pass through to pi as a regular prompt
    pi.send_prompt(text)
  end
end

return M
