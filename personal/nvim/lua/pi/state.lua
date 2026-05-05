local M = {}

-- Global plugin state
M.agents = {} -- agent_id -> { job_id, cwd, session_file, chat_bufnr, input_bufnr, model, name, state }
M.active_agent_id = nil
M.is_streaming = false
M.tool_els = {} -- tool_call_id -> { line_start, line_end, name, args, status }
M.pending_tool_calls = {} -- tool_call_id -> { name, args } (from toolcall_end before tool_execution_start)
M.current_assistant_text = ""
M.current_assistant_line_start = nil

function M.get_active_agent()
  if M.active_agent_id and M.agents[M.active_agent_id] then
    return M.agents[M.active_agent_id]
  end
  return nil
end

function M.reset()
  M.agents = {}
  M.active_agent_id = nil
  M.is_streaming = false
  M.tool_els = {}
  M.pending_tool_calls = {}
  M.current_assistant_text = ""
  M.current_assistant_line_start = nil
end

return M
