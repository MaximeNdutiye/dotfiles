local events = require("pi.events")
local state = require("pi.state")
local config = require("pi.config")

local M = {}

-- Per-agent line buffers for partial JSONL chunks
local line_buffers = {} -- job_id -> string

-- RPC request/response correlation
local rpc_seq = 0
local rpc_pending = {} -- id -> { callback, timer }

function M.spawn(cwd, session_file)
  local cfg = config.get()
  local args = { cfg.pi_binary, "--mode", "rpc" }
  if session_file then
    table.insert(args, "--session")
    table.insert(args, session_file)
  end

  local agent_id = string.format("%s_%d", os.time(), math.random(10000, 99999))
  line_buffers[agent_id] = ""

  local job_id = vim.fn.jobstart(args, {
    cwd = cwd,
    env = { FORCE_COLOR = "0" },
    on_stdout = function(_, data, _)
      M._on_stdout(agent_id, data)
    end,
    on_stderr = function(_, data, _)
      M._on_stderr(agent_id, data)
    end,
    on_exit = function(_, code, _)
      vim.schedule(function()
        M._on_exit(agent_id, code)
      end)
    end,
    stdout_buffered = false,
    stderr_buffered = false,
  })

  if job_id <= 0 then
    return nil, "Failed to spawn pi process"
  end

  return agent_id, job_id
end

function M._on_stdout(agent_id, data)
  if not data then return end

  -- vim.fn.jobstart sends data as a list of strings split by newlines
  -- Join them back with newlines, handling partial lines via buffer
  local buf = line_buffers[agent_id] or ""

  for i, chunk in ipairs(data) do
    if i == 1 then
      -- First chunk continues from previous partial line
      buf = buf .. chunk
    else
      -- Subsequent chunks mean there was a newline before them
      -- Process the completed line
      local line = buf
      buf = chunk

      -- Strip trailing \r
      if line:sub(-1) == "\r" then
        line = line:sub(1, -2)
      end

      -- Process non-empty lines
      if line:match("%S") then
        local ok, decoded = pcall(vim.json.decode, line)
        if ok and decoded then
          vim.schedule(function()
            M._dispatch_event(agent_id, decoded)
          end)
        end
      end
    end
  end

  line_buffers[agent_id] = buf
end

function M._on_stderr(agent_id, data)
  if not data then return end
  local text = table.concat(data, "\n")
  if text:match("%S") then
    vim.schedule(function()
      events.emit("stderr", { agent_id = agent_id, text = text })
    end)
  end
end

function M._on_exit(agent_id, code)
  line_buffers[agent_id] = nil
  events.emit("exit", { agent_id = agent_id, code = code })
end

function M._dispatch_event(agent_id, event)
  -- Route RPC responses to pending callbacks
  if event.type == "response" then
    if event.id and rpc_pending[event.id] then
      local pending = rpc_pending[event.id]
      rpc_pending[event.id] = nil
      if pending.timer then
        vim.fn.timer_stop(pending.timer)
      end
      if pending.callback then
        pending.callback(event)
      end
      return
    end
  end

  -- Emit all events with agent_id attached
  event.agent_id = agent_id
  events.emit(event.type or "unknown", event)
end

function M.send(agent_id, command)
  local agent = state.agents[agent_id]
  if not agent then return false end
  local json = vim.json.encode(command) .. "\n"
  vim.fn.chansend(agent.job_id, json)
  return true
end

function M.rpc_call(agent_id, command, callback)
  local agent = state.agents[agent_id]
  if not agent then
    if callback then callback({ success = false, error = "No agent" }) end
    return
  end

  rpc_seq = rpc_seq + 1
  local id = "rpc-" .. rpc_seq
  command.id = id

  local timer = vim.fn.timer_start(config.get().rpc_timeout, function()
    if rpc_pending[id] then
      rpc_pending[id] = nil
      if callback then
        vim.schedule(function()
          callback({ success = false, error = "RPC timeout" })
        end)
      end
    end
  end)

  rpc_pending[id] = { callback = callback, timer = timer }
  M.send(agent_id, command)
end

-- Promise-style rpc_call using coroutines
function M.rpc_call_async(agent_id, command)
  local co = coroutine.running()
  if not co then
    error("rpc_call_async must be called from a coroutine")
  end

  M.rpc_call(agent_id, command, function(result)
    vim.schedule(function()
      coroutine.resume(co, result)
    end)
  end)

  return coroutine.yield()
end

function M.kill(agent_id)
  local agent = state.agents[agent_id]
  if not agent then return end
  pcall(vim.fn.jobstop, agent.job_id)
end

return M
