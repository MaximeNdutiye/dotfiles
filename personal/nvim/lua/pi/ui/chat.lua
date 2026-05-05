local config = require("pi.config")
local state = require("pi.state")
local events = require("pi.events")
local tools = require("pi.ui.tools")
local layout = require("pi.ui.layout")

local M = {}

-- Create a chat buffer for an agent
function M.create_buffer(agent_id)
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].filetype = "markdown"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].modifiable = false

  local agent = state.agents[agent_id]
  local short_path = agent and agent.cwd and vim.fn.fnamemodify(agent.cwd, ":~") or "pi"
  vim.api.nvim_buf_set_name(bufnr, "pi://" .. short_path)

  -- Set up buffer-local keymaps
  M.setup_keymaps(bufnr)

  return bufnr
end

function M.setup_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- q to close chat window
  vim.keymap.set("n", "q", function()
    layout.close()
  end, opts)

  -- / to focus input
  vim.keymap.set("n", "/", function()
    layout.focus_input()
  end, opts)

  -- <C-c> to abort streaming
  vim.keymap.set("n", "<C-c>", function()
    local pi = require("pi")
    pi.abort()
  end, opts)
end

-- Append lines to chat buffer
function M.append_lines(bufnr, lines)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  local count = vim.api.nvim_buf_line_count(bufnr)
  -- If buffer is empty (single empty line), replace it
  if count == 1 then
    local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
    if first[1] == "" then
      vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, lines)
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
      return
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, count, count, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

-- Clear the chat buffer
function M.clear(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

-- Add a system message
function M.add_system_msg(bufnr, text)
  M.append_lines(bufnr, { "", "> " .. text, "" })
  M.auto_scroll()
end

-- Add a user message
function M.add_user_msg(bufnr, text)
  local lines = { "", "---", "", "## You", "" }
  for _, line in ipairs(vim.split(text, "\n")) do
    table.insert(lines, line)
  end
  table.insert(lines, "")
  M.append_lines(bufnr, lines)
  M.auto_scroll()
end

-- Start an assistant message block (for streaming)
function M.start_assistant_msg(bufnr)
  local lines = { "", "---", "", "## Pi", "" }
  M.append_lines(bufnr, lines)
  -- Track where the streaming content starts
  state.current_assistant_line_start = vim.api.nvim_buf_line_count(bufnr)
  state.current_assistant_text = ""
end

-- Update the streaming assistant message
function M.update_assistant_streaming(bufnr, text)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if not state.current_assistant_line_start then
    M.start_assistant_msg(bufnr)
  end

  local content_lines = vim.split(text, "\n")

  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  -- Replace from assistant content start to end
  local start_line = state.current_assistant_line_start - 1 -- 0-indexed
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, start_line, line_count, false, content_lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  M.auto_scroll()
end

-- Finalize assistant message (re-render with full markdown)
function M.finalize_assistant_msg(bufnr)
  if state.current_assistant_text ~= "" and state.current_assistant_line_start then
    M.update_assistant_streaming(bufnr, state.current_assistant_text)
  end
  state.current_assistant_line_start = nil
  state.current_assistant_text = ""
end

-- Add a complete assistant message (for history loading)
function M.add_assistant_msg(bufnr, text)
  local lines = { "", "---", "", "## Pi", "" }
  for _, line in ipairs(vim.split(text, "\n")) do
    table.insert(lines, line)
  end
  table.insert(lines, "")
  M.append_lines(bufnr, lines)
end

-- Add a thinking message
function M.add_thinking_msg(bufnr, text)
  local short = text:sub(1, 200)
  if #text > 200 then short = short .. "…" end
  M.append_lines(bufnr, { "", "> 💭 " .. short, "" })
end

-- Add a tool result from history
function M.add_tool_result(bufnr, tool_name, result, is_error)
  local tool_call_id = "hist-" .. tostring(math.random(10000, 99999))
  tools.render_tool_start(bufnr, tool_call_id, tool_name, {})
  tools.finish_tool(bufnr, tool_call_id, result, is_error, {})
end

function M.auto_scroll()
  if config.get().auto_scroll then
    layout.scroll_to_bottom()
  end
end

-- Render full chat history from get_messages response
function M.render_history(bufnr, messages)
  M.clear(bufnr)

  for _, m in ipairs(messages) do
    if m.role == "user" then
      local text
      if type(m.content) == "string" then
        text = m.content
      elseif type(m.content) == "table" and m.content[1] then
        text = m.content[1].text or ""
      else
        text = ""
      end
      M.add_user_msg(bufnr, text)
    elseif m.role == "assistant" then
      local content = m.content
      if type(content) == "table" then
        for _, part in ipairs(content) do
          if part.type == "text" and part.text then
            M.add_assistant_msg(bufnr, part.text)
          elseif part.type == "thinking" and part.thinking then
            M.add_thinking_msg(bufnr, part.thinking)
          end
        end
      end
    elseif m.role == "toolResult" then
      M.add_tool_result(bufnr, m.toolName or "tool", m, m.isError)
    end
  end

  M.auto_scroll()
end

-- Setup event listeners for chat rendering
function M.setup_events()
  -- Streaming text deltas
  events.on("message_update", function(event)
    if event.agent_id ~= state.active_agent_id then return end

    local d = event.assistantMessageEvent
    if not d then return end

    if d.type == "text_delta" then
      local agent = state.get_active_agent()
      if not agent or not agent.chat_bufnr then return end

      state.current_assistant_text = state.current_assistant_text .. (d.delta or "")
      M.update_assistant_streaming(agent.chat_bufnr, state.current_assistant_text)
    end

    -- Capture tool call info
    if d.type == "toolcall_end" and d.toolCall then
      local tc = d.toolCall
      local args = tc.arguments
      if type(args) == "string" then
        local ok, decoded = pcall(vim.json.decode, args)
        if ok then args = decoded end
      end
      state.pending_tool_calls[tc.id] = { name = tc.name, args = args }
    end
  end)

  -- Agent start
  events.on("agent_start", function(event)
    if event.agent_id ~= state.active_agent_id then return end
    state.is_streaming = true
    state.current_assistant_text = ""
    state.current_assistant_line_start = nil
  end)

  -- Agent end
  events.on("agent_end", function(event)
    if event.agent_id ~= state.active_agent_id then return end
    state.is_streaming = false

    local agent = state.get_active_agent()
    if agent and agent.chat_bufnr then
      M.finalize_assistant_msg(agent.chat_bufnr)
    end
  end)

  -- Message end
  events.on("message_end", function(event)
    if event.agent_id ~= state.active_agent_id then return end

    if event.message and event.message.role == "assistant" then
      local agent = state.get_active_agent()
      if agent and agent.chat_bufnr then
        M.finalize_assistant_msg(agent.chat_bufnr)
      end
    end
  end)

  -- Tool execution start
  events.on("tool_execution_start", function(event)
    if event.agent_id ~= state.active_agent_id then return end

    local agent = state.get_active_agent()
    if not agent or not agent.chat_bufnr then return end

    -- Finalize any in-progress assistant text before tool output
    if state.current_assistant_text ~= "" then
      M.finalize_assistant_msg(agent.chat_bufnr)
    end

    -- Check for pending tool call info
    local args = event.args
    local pending = state.pending_tool_calls[event.toolCallId]
    if pending then
      if not args or (type(args) == "table" and vim.tbl_isempty(args)) then
        args = pending.args
      end
      state.pending_tool_calls[event.toolCallId] = nil
    end

    tools.render_tool_start(agent.chat_bufnr, event.toolCallId, event.toolName, args)
    M.auto_scroll()
  end)

  -- Tool execution update
  events.on("tool_execution_update", function(event)
    if event.agent_id ~= state.active_agent_id then return end

    local agent = state.get_active_agent()
    if not agent or not agent.chat_bufnr then return end

    tools.update_tool_streaming(agent.chat_bufnr, event.toolCallId, event.partialResult, event.args)
    M.auto_scroll()
  end)

  -- Tool execution end
  events.on("tool_execution_end", function(event)
    if event.agent_id ~= state.active_agent_id then return end

    local agent = state.get_active_agent()
    if not agent or not agent.chat_bufnr then return end

    tools.finish_tool(agent.chat_bufnr, event.toolCallId, event.result, event.isError, event.args)
    M.auto_scroll()
  end)

  -- System messages
  events.on("system_message", function(event)
    local agent = state.get_active_agent()
    if agent and agent.chat_bufnr then
      M.add_system_msg(agent.chat_bufnr, event.text)
    end
  end)

  -- Auto compaction
  events.on("auto_compaction_start", function(event)
    if event.agent_id ~= state.active_agent_id then return end
    local agent = state.get_active_agent()
    if agent and agent.chat_bufnr then
      M.add_system_msg(agent.chat_bufnr, "📦 Compacting context…")
    end
  end)

  events.on("auto_compaction_end", function(event)
    if event.agent_id ~= state.active_agent_id then return end
    local agent = state.get_active_agent()
    if agent and agent.chat_bufnr then
      M.add_system_msg(agent.chat_bufnr, "📦 Context compacted")
    end
  end)
end

return M
