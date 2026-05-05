local rpc = require("pi.rpc")
local state = require("pi.state")
local events = require("pi.events")

local M = {}

function M.spawn(cwd, session_file)
  cwd = cwd or vim.fn.getcwd()

  local agent_id, job_id = rpc.spawn(cwd, session_file)
  if not agent_id then
    vim.notify("[pi.nvim] Failed to spawn pi: " .. tostring(job_id), vim.log.levels.ERROR)
    return nil
  end

  state.agents[agent_id] = {
    job_id = job_id,
    cwd = cwd,
    session_file = session_file,
    chat_bufnr = nil,
    input_bufnr = nil,
    model = nil,
    name = nil,
    state = "starting",
  }

  return agent_id
end

function M.kill(agent_id)
  agent_id = agent_id or state.active_agent_id
  if not agent_id then return end

  rpc.kill(agent_id)
  state.agents[agent_id] = nil

  if state.active_agent_id == agent_id then
    state.active_agent_id = nil
    -- Switch to another agent if available
    for id, _ in pairs(state.agents) do
      M.switch(id)
      return
    end
  end
end

function M.send(agent_id, command)
  return rpc.send(agent_id or state.active_agent_id, command)
end

function M.rpc_call(command, callback)
  rpc.rpc_call(state.active_agent_id, command, callback)
end

-- Async version for use in coroutines
function M.rpc_call_async(command)
  return rpc.rpc_call_async(state.active_agent_id, command)
end

function M.switch(agent_id)
  if not state.agents[agent_id] then return false end

  local prev_id = state.active_agent_id
  state.active_agent_id = agent_id
  state.is_streaming = false
  state.current_assistant_text = ""
  state.current_assistant_line_start = nil
  state.tool_els = {}
  state.pending_tool_calls = {}

  events.emit("agent_switched", {
    agent_id = agent_id,
    prev_agent_id = prev_id,
  })

  return true
end

function M.list()
  local result = {}
  for id, agent in pairs(state.agents) do
    table.insert(result, {
      id = id,
      cwd = agent.cwd,
      session_file = agent.session_file,
      model = agent.model,
      name = agent.name,
      is_active = id == state.active_agent_id,
      state = agent.state,
    })
  end
  return result
end

function M.get_active()
  return state.active_agent_id, state.get_active_agent()
end

-- Initialize agent: poll get_state until ready, then load messages
function M.initialize(agent_id, on_ready)
  local attempts = 0
  local max_attempts = 60

  local function poll()
    if not state.agents[agent_id] then return end
    if state.active_agent_id ~= agent_id then return end

    attempts = attempts + 1
    if attempts > max_attempts then
      events.emit("system_message", { text = "Pi failed to initialize" })
      return
    end

    rpc.rpc_call(agent_id, { type = "get_state" }, function(res)
      if not state.agents[agent_id] then return end

      if res and res.success then
        local agent = state.agents[agent_id]
        if res.data then
          if res.data.model then
            agent.model = res.data.model.name or res.data.model.id
          end
          if res.data.sessionName then
            agent.name = res.data.sessionName
          end
        end
        agent.state = "ready"
        if on_ready then on_ready() end
      else
        -- Retry after 500ms
        vim.defer_fn(poll, 500)
      end
    end)
  end

  poll()
end

-- Load chat history for an agent
function M.load_messages(agent_id, callback)
  rpc.rpc_call(agent_id, { type = "get_messages" }, function(res)
    if res and res.success and res.data then
      callback(res.data.messages or {})
    else
      callback({})
    end
  end)
end

-- Setup event listeners for agent lifecycle
function M.setup_events()
  -- Handle agent exit
  events.on("exit", function(data)
    local agent_id = data.agent_id
    if state.agents[agent_id] then
      state.agents[agent_id] = nil
    end
    if state.active_agent_id == agent_id then
      state.active_agent_id = nil
      state.is_streaming = false
      events.emit("system_message", {
        text = string.format("Pi exited (code %s)", tostring(data.code)),
      })
    end
  end)
end

return M
