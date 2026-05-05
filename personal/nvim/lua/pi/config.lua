local M = {}

M.defaults = {
  pi_binary = "pi",
  chat_width = 80,
  chat_position = "right", -- "right" | "bottom" | "float"
  auto_scroll = true,
  session_dir = vim.fn.expand("~/.pi/agent/sessions"),
  rpc_timeout = 30000, -- ms
  max_tool_output_lines = 200,
  update_interval = 50, -- ms between streaming buffer updates
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

function M.get()
  return M.options
end

return M
