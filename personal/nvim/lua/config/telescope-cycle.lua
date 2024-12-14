local telescope_builtin = require "telescope.builtin"
local telescope_state = require "telescope.actions.state"

return function(...)
  -- create a new cycle picker with the given pickers to cycle trough
  local pickers = { ... }
  if #pickers == 0 then
    pickers = {
      telescope_builtin.find_files,
      telescope_builtin.live_grep,
      telescope_builtin.grep_string,
      telescope_builtin.buffers,
    }
  end

  -- although lua tables are indexed from 1 one start with 0 because it is
  -- easier to do the modulo stuff 0 based and just add 1 when accessing the
  -- table.
  local index = 0

  -- the picker object we will return
  local cycle = {}
  function cycle.cycle(step)
    step = step or 1
    index = (index + step) % #pickers
    pickers[index + 1] {
      default_text = telescope_state.get_current_line(),
      search_dirs = { vim.fn.finddir('.git/..', vim.fn.expand('%:p:h') .. ";") },
    }
  end

  function cycle.next() cycle.cycle(1) end

  function cycle.previous() cycle.cycle(-1) end

  -- return a dynamically created cycle picker with the given pickers
  -- we are creating a table that is callable
  return setmetatable(cycle, {
    __call = function(opts)
      index = 0
      pickers[index + 1](opts)
    end
  })
end
