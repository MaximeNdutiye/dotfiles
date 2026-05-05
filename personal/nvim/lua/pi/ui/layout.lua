local config = require("pi.config")
local state = require("pi.state")

local M = {}

-- Window IDs
M.chat_win = nil
M.input_win = nil

function M.is_open()
  return M.chat_win and vim.api.nvim_win_is_valid(M.chat_win)
end

function M.open(chat_bufnr, input_bufnr)
  if M.is_open() then
    -- Already open, just switch buffers
    vim.api.nvim_win_set_buf(M.chat_win, chat_bufnr)
    if M.input_win and vim.api.nvim_win_is_valid(M.input_win) then
      vim.api.nvim_win_set_buf(M.input_win, input_bufnr)
    end
    return
  end

  local cfg = config.get()

  -- Create chat split on the right
  vim.cmd("botright vsplit")
  M.chat_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.chat_win, chat_bufnr)
  vim.api.nvim_win_set_width(M.chat_win, cfg.chat_width)

  -- Window options for chat
  vim.wo[M.chat_win].wrap = true
  vim.wo[M.chat_win].linebreak = true
  vim.wo[M.chat_win].number = false
  vim.wo[M.chat_win].relativenumber = false
  vim.wo[M.chat_win].signcolumn = "no"
  vim.wo[M.chat_win].foldmethod = "manual"
  vim.wo[M.chat_win].foldenable = true
  vim.wo[M.chat_win].cursorline = false
  vim.wo[M.chat_win].spell = false
  vim.wo[M.chat_win].winfixwidth = true

  -- Create input split below chat
  vim.cmd("belowright split")
  M.input_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.input_win, input_bufnr)
  vim.api.nvim_win_set_height(M.input_win, 3)

  -- Window options for input
  vim.wo[M.input_win].wrap = true
  vim.wo[M.input_win].linebreak = true
  vim.wo[M.input_win].number = false
  vim.wo[M.input_win].relativenumber = false
  vim.wo[M.input_win].signcolumn = "no"
  vim.wo[M.input_win].cursorline = false
  vim.wo[M.input_win].spell = false
  vim.wo[M.input_win].winfixheight = true

  -- Focus the input window
  vim.api.nvim_set_current_win(M.input_win)
end

function M.close()
  if M.input_win and vim.api.nvim_win_is_valid(M.input_win) then
    vim.api.nvim_win_close(M.input_win, true)
    M.input_win = nil
  end
  if M.chat_win and vim.api.nvim_win_is_valid(M.chat_win) then
    vim.api.nvim_win_close(M.chat_win, true)
    M.chat_win = nil
  end
end

function M.toggle(chat_bufnr, input_bufnr)
  if M.is_open() then
    M.close()
  else
    M.open(chat_bufnr, input_bufnr)
  end
end

function M.focus_input()
  if M.input_win and vim.api.nvim_win_is_valid(M.input_win) then
    vim.api.nvim_set_current_win(M.input_win)
    vim.cmd("startinsert")
  end
end

function M.focus_chat()
  if M.chat_win and vim.api.nvim_win_is_valid(M.chat_win) then
    vim.api.nvim_set_current_win(M.chat_win)
  end
end

function M.scroll_to_bottom()
  if M.chat_win and vim.api.nvim_win_is_valid(M.chat_win) then
    local chat_bufnr = vim.api.nvim_win_get_buf(M.chat_win)
    local line_count = vim.api.nvim_buf_line_count(chat_bufnr)
    vim.api.nvim_win_set_cursor(M.chat_win, { line_count, 0 })
  end
end

return M
