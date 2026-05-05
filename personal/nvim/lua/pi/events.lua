local M = {}

-- Simple pub/sub event system
local listeners = {}

function M.on(event_type, callback)
  if not listeners[event_type] then
    listeners[event_type] = {}
  end
  table.insert(listeners[event_type], callback)
  -- Return unsubscribe function
  return function()
    for i, cb in ipairs(listeners[event_type] or {}) do
      if cb == callback then
        table.remove(listeners[event_type], i)
        break
      end
    end
  end
end

function M.emit(event_type, data)
  for _, cb in ipairs(listeners[event_type] or {}) do
    local ok, err = pcall(cb, data)
    if not ok then
      vim.schedule(function()
        vim.notify("[pi.nvim] Event handler error (" .. event_type .. "): " .. tostring(err), vim.log.levels.ERROR)
      end)
    end
  end
end

function M.clear()
  listeners = {}
end

return M
