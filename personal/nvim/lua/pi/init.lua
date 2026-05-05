local config = require("pi.config")
local state = require("pi.state")
local events = require("pi.events")
local agent = require("pi.agent")
local rpc = require("pi.rpc")
local chat = require("pi.ui.chat")
local input = require("pi.ui.input")
local layout = require("pi.ui.layout")
local git = require("pi.git")

local M = {}

-- Helper to run async code in a coroutine
function M.run_async(fn)
  local co = coroutine.create(fn)
  local ok, err = coroutine.resume(co)
  if not ok then
    vim.notify("[pi.nvim] Async error: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.setup(opts)
  config.setup(opts)
  agent.setup_events()
  chat.setup_events()
  M.create_commands()
  M.create_keymaps()
end

-- Open or toggle the Pi chat window
function M.open(cwd)
  cwd = cwd or vim.fn.getcwd()

  local agent_id = state.active_agent_id
  local ag = state.get_active_agent()

  if agent_id and ag then
    -- Already have an active agent, just toggle the window
    layout.toggle(ag.chat_bufnr, ag.input_bufnr)
    return
  end

  -- Spawn a new agent
  M.connect_to_session(cwd, nil)
end

-- Connect to a session (new or existing)
function M.connect_to_session(cwd, session_file)
  -- Spawn agent
  local agent_id = agent.spawn(cwd, session_file)
  if not agent_id then return end

  -- Create UI buffers
  local chat_bufnr = chat.create_buffer(agent_id)
  local input_bufnr = input.create_buffer(agent_id)

  -- Store buffer references
  local ag = state.agents[agent_id]
  ag.chat_bufnr = chat_bufnr
  ag.input_bufnr = input_bufnr

  -- Switch to this agent
  agent.switch(agent_id)

  -- Open the layout
  layout.open(chat_bufnr, input_bufnr)

  -- Show initializing message
  chat.add_system_msg(chat_bufnr, "Starting pi…")

  -- Initialize agent (poll get_state, then load messages)
  agent.initialize(agent_id, function()
    if state.active_agent_id ~= agent_id then return end

    vim.schedule(function()
      local a = state.agents[agent_id]
      if not a then return end

      chat.add_system_msg(chat_bufnr, "Waiting for pi to initialize…")

      -- Load message history
      agent.load_messages(agent_id, function(messages)
        vim.schedule(function()
          if state.active_agent_id ~= agent_id then return end
          if #messages > 0 then
            chat.render_history(chat_bufnr, messages)
          end
          chat.add_system_msg(chat_bufnr, "Ready.")
          layout.focus_input()
        end)
      end)
    end)
  end)
end

-- Grab the most recent visual selection (works whether you call it from
-- visual mode directly via <cmd>... or after `:` left visual mode and set
-- the '<,'> marks). Returns the raw selected text, plus start/end lines.
function M.get_visual_selection()
  -- If we're still in visual mode, exit it so the '<,'> marks are committed.
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("normal! \27") -- <Esc>
  end

  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local sline, scol = s[2], s[3]
  local eline, ecol = e[2], e[3]
  if sline == 0 or eline == 0 then return nil end

  local lines = vim.fn.getline(sline, eline)
  if type(lines) ~= "table" or #lines == 0 then return nil end

  -- Trim to character columns when it was a charwise selection.
  -- For linewise (V) selections the cols are 1 / huge, so the slicing is a no-op.
  if vim.fn.visualmode() == "v" then
    -- Lua strings are 1-indexed; ecol may be MAXINT for end-of-line in V-mode.
    lines[#lines] = string.sub(lines[#lines], 1, ecol)
    lines[1] = string.sub(lines[1], scol)
  end

  return table.concat(lines, "\n"), sline, eline
end

-- Send the current visual selection to the active pi agent, wrapped in a
-- markdown code block with file path + line numbers so pi can locate it.
-- If `question` is non-empty it's prepended above the code block.
function M.send_visual_selection(question)
  local text, sline, eline = M.get_visual_selection()
  if not text or text == "" then
    vim.notify("[pi.nvim] No visual selection", vim.log.levels.WARN)
    return
  end

  if not state.active_agent_id then
    -- Spin up a session in the current cwd if none exists yet.
    M.open()
  end

  local file = vim.fn.expand("%:.")
  if file == "" then file = "[unnamed buffer]" end
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or ""
  local header = string.format("From `%s:%d-%d`:", file, sline, eline)
  local body = string.format("%s\n```%s\n%s\n```", header, ft, text)
  local message = (question and question ~= "") and (question .. "\n\n" .. body) or body
  M.send_prompt(message)
end

-- Send a prompt to the active agent
function M.send_prompt(text)
  if not state.active_agent_id then
    vim.notify("[pi.nvim] No active agent", vim.log.levels.WARN)
    return
  end

  local ag = state.get_active_agent()
  if ag and ag.chat_bufnr then
    chat.add_user_msg(ag.chat_bufnr, text)
  end

  local cmd = { type = "prompt", message = text }
  if state.is_streaming then
    cmd.streamingBehavior = "followUp"
  end
  agent.send(state.active_agent_id, cmd)
end

-- Abort current streaming
function M.abort()
  if state.active_agent_id then
    agent.send(state.active_agent_id, { type = "abort" })
  end
end

-- Switch to a different running agent
function M.switch_agent(agent_id)
  if not agent.switch(agent_id) then return end
  local ag = state.agents[agent_id]
  if ag and ag.chat_bufnr and ag.input_bufnr then
    layout.open(ag.chat_bufnr, ag.input_bufnr)
    layout.focus_input()
  end
end

-- Slash commands
function M.cmd_model()
  require("pi.telescope.models").pick()
end

function M.cmd_thinking()
  require("pi.telescope.thinking").pick()
end

function M.cmd_compact(args)
  local ag = state.get_active_agent()
  if ag and ag.chat_bufnr then
    chat.add_system_msg(ag.chat_bufnr, "📦 Compacting…")
  end

  M.run_async(function()
    local cmd = { type = "compact" }
    if args and args ~= "" then cmd.customInstructions = args end
    local res = agent.rpc_call_async(cmd)
    vim.schedule(function()
      if res and res.success then
        local before = ""
        if res.data and res.data.tokensBefore then
          before = string.format(" (was %s tokens)", vim.fn.printf("%d", res.data.tokensBefore))
        end
        if ag and ag.chat_bufnr then
          chat.add_system_msg(ag.chat_bufnr, "📦 Compacted" .. before)
        end
      else
        vim.notify("[pi.nvim] Failed to compact", vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.cmd_new()
  M.run_async(function()
    local res = agent.rpc_call_async({ type = "new_session" })
    vim.schedule(function()
      if res and res.success and not (res.data and res.data.cancelled) then
        local ag = state.get_active_agent()
        if ag and ag.chat_bufnr then
          chat.clear(ag.chat_bufnr)
          chat.add_system_msg(ag.chat_bufnr, "New session started")
        end
      end
    end)
  end)
end

function M.cmd_session()
  M.run_async(function()
    local res = agent.rpc_call_async({ type = "get_session_stats" })
    vim.schedule(function()
      if res and res.success and res.data then
        local d = res.data
        local cost = d.cost and string.format("$%.4f", d.cost) or "n/a"
        local tok = d.tokens or {}
        local msg = string.format(
          "📊 %d user / %d assistant msgs · %d tool calls\n" ..
          "   %d tokens (%d in · %d out · %d cache) · %s",
          d.userMessages or 0, d.assistantMessages or 0, d.toolCalls or 0,
          tok.total or 0, tok.input or 0, tok.output or 0, tok.cacheRead or 0, cost
        )
        local ag = state.get_active_agent()
        if ag and ag.chat_bufnr then
          chat.add_system_msg(ag.chat_bufnr, msg)
        end
      else
        vim.notify("[pi.nvim] Failed to get stats", vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.cmd_name(args)
  if not args or args == "" then
    vim.notify("[pi.nvim] Usage: /name <session name>", vim.log.levels.WARN)
    return
  end
  M.run_async(function()
    local res = agent.rpc_call_async({ type = "set_session_name", name = args })
    vim.schedule(function()
      if res and res.success then
        local ag = state.get_active_agent()
        if ag then ag.name = args end
        vim.notify('[pi.nvim] Session → "' .. args .. '"')
      end
    end)
  end)
end

function M.cmd_export()
  M.run_async(function()
    local res = agent.rpc_call_async({ type = "export_html" })
    vim.schedule(function()
      if res and res.success then
        vim.notify("[pi.nvim] Exported to " .. (res.data and res.data.path or ""))
      else
        vim.notify("[pi.nvim] Export failed", vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.cmd_copy()
  M.run_async(function()
    local res = agent.rpc_call_async({ type = "get_last_assistant_text" })
    vim.schedule(function()
      if res and res.success and res.data and res.data.text then
        vim.fn.setreg("+", res.data.text)
        vim.notify("[pi.nvim] Copied to clipboard")
      else
        vim.notify("[pi.nvim] Nothing to copy", vim.log.levels.INFO)
      end
    end)
  end)
end

function M.cmd_help()
  local ag = state.get_active_agent()
  if not ag or not ag.chat_bufnr then return end

  local lines = {
    "**Commands**",
    "",
    "`/model` — Switch model",
    "`/thinking` — Set thinking level",
    "`/compact` — Compact context",
    "`/new` — New session",
    "`/session` — Session info & stats",
    "`/name` — Set session name",
    "`/export` — Export to HTML",
    "`/copy` — Copy last response",
    "`/help` — Show all commands",
  }
  chat.add_assistant_msg(ag.chat_bufnr, table.concat(lines, "\n"))
end

-- Git changes for active agent's cwd
function M.show_changes()
  local ag = state.get_active_agent()
  if not ag then
    vim.notify("[pi.nvim] No active agent", vim.log.levels.WARN)
    return
  end
  git.show_changes(ag.cwd)
end

-- Open terminal in agent's cwd via toggleterm
function M.open_terminal()
  local ag = state.get_active_agent()
  if not ag then
    vim.notify("[pi.nvim] No active agent", vim.log.levels.WARN)
    return
  end

  local ok, toggleterm = pcall(require, "toggleterm.terminal")
  if ok then
    local Terminal = toggleterm.Terminal
    local term = Terminal:new({ dir = ag.cwd })
    term:toggle()
  else
    -- Fallback: open a terminal split
    vim.cmd("belowright split | terminal")
    vim.fn.chansend(vim.b.terminal_job_id, "cd " .. vim.fn.shellescape(ag.cwd) .. "\n")
  end
end

-- Statusline component
function M.statusline()
  local ag = state.get_active_agent()
  if not ag then return "" end

  local parts = {}
  if ag.name then
    table.insert(parts, ag.name)
  else
    table.insert(parts, vim.fn.fnamemodify(ag.cwd, ":t"))
  end
  if ag.model then
    table.insert(parts, ag.model)
  end
  if state.is_streaming then
    table.insert(parts, "⟳")
  end
  return "π " .. table.concat(parts, " · ")
end

-- Register vim commands
function M.create_commands()
  vim.api.nvim_create_user_command("Pi", function(opts)
    local cwd = opts.args ~= "" and opts.args or nil
    M.open(cwd)
  end, { nargs = "?", complete = "dir" })

  vim.api.nvim_create_user_command("PiSend", function(opts)
    M.send_prompt(opts.args)
  end, { nargs = "+" })

  vim.api.nvim_create_user_command("PiNew", function(opts)
    local cwd = opts.args ~= "" and opts.args or nil
    M.connect_to_session(cwd or vim.fn.getcwd(), nil)
  end, { nargs = "?", complete = "dir" })

  vim.api.nvim_create_user_command("PiSession", function()
    require("pi.telescope.sessions").pick()
  end, {})

  vim.api.nvim_create_user_command("PiKill", function()
    agent.kill(state.active_agent_id)
    layout.close()
  end, {})

  vim.api.nvim_create_user_command("PiModels", function()
    M.cmd_model()
  end, {})

  vim.api.nvim_create_user_command("PiThinking", function()
    M.cmd_thinking()
  end, {})

  vim.api.nvim_create_user_command("PiCompact", function(opts)
    M.cmd_compact(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("PiChanges", function()
    M.show_changes()
  end, {})

  vim.api.nvim_create_user_command("PiAgents", function()
    require("pi.telescope.agents").pick()
  end, {})

  vim.api.nvim_create_user_command("PiStats", function()
    M.cmd_session()
  end, {})

  vim.api.nvim_create_user_command("PiTerminal", function()
    M.open_terminal()
  end, {})

  vim.api.nvim_create_user_command("PiName", function(opts)
    M.cmd_name(opts.args)
  end, { nargs = "+" })
end

-- Register global keymaps
function M.create_keymaps()
  vim.keymap.set("n", "<leader>pi", "<cmd>Pi<cr>", { desc = "Toggle Pi chat" })
  vim.keymap.set("n", "<leader>ps", "<cmd>PiSession<cr>", { desc = "Pi sessions" })
  vim.keymap.set("n", "<leader>pm", "<cmd>PiModels<cr>", { desc = "Pi models" })
  vim.keymap.set("n", "<leader>pa", "<cmd>PiAgents<cr>", { desc = "Pi agents" })
  vim.keymap.set("n", "<leader>pk", "<cmd>PiKill<cr>", { desc = "Kill Pi agent" })

  -- Visual-mode: send the current selection to pi.
  vim.keymap.set("x", "<leader>pv", function() M.send_visual_selection() end,
    { desc = "Pi: send visual selection" })
  vim.keymap.set("x", "<leader>pV", function()
    -- Capture before vim.ui.input so we don't lose the selection while typing.
    local text, sline, eline = M.get_visual_selection()
    vim.ui.input({ prompt = "Ask pi about selection: " }, function(input)
      if not input then return end
      if not text or text == "" then
        vim.notify("[pi.nvim] No visual selection", vim.log.levels.WARN)
        return
      end
      if not state.active_agent_id then M.open() end
      local file = vim.fn.expand("%:.")
      if file == "" then file = "[unnamed buffer]" end
      local ft = vim.bo.filetype ~= "" and vim.bo.filetype or ""
      local body = string.format("From `%s:%d-%d`:\n```%s\n%s\n```",
        file, sline, eline, ft, text)
      M.send_prompt(input .. "\n\n" .. body)
    end)
  end, { desc = "Pi: ask about visual selection" })
end

return M
