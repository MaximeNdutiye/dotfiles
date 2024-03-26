local ts_repeat_move = require "nvim-treesitter.textobjects.repeatable_move"

-- Repeat movement with ; and ,
-- ensure ; goes forward and , goes backward regardless of the last direction
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

-- vim way: ; goes to the direction you were moving.
-- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
-- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f)
vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F)
vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t)
vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T)

local telescope_builtin = require "telescope.builtin"
local telescope_state = require "telescope.actions.state"

function cycle_my_picker(...)
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
    pickers[index + 1] { default_text = telescope_state.get_current_line() }
  end

  function cycle.next() cycle.cycle(1) end

  function cycle.previous() cycle.cycle(-1) end

  -- return a dynamically created cycle picker with the given pickers
  return setmetatable(cycle, {
    __call = function(opts)
      index = 0
      pickers[index + 1](opts)
    end
  })
end

local cycle = cycle_my_picker(
  function()
    local sorter = require 'telescope.config'.values.file_sorter()
    require 'telescope'.extensions.frecency.frecency { sorter = sorter }
  end,
  telescope_builtin.find_files,
  telescope_builtin.live_grep,
  telescope_builtin.grep_string,
  telescope_builtin.buffers
)

return {
  n = {
    ["<leader>ca"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      desc = "Code Action",
    },
    ["<leader>tr"] = {
      "<cmd>Telescope resume<cr>",
      desc = "Telescope Resume"
    },
    ["<leader>fq"] = {
      function()
        vim.lsp.buf.format()
      end,
      desc = "Format file",
    },
    ["tn"] = {
      "<cmd>TestNearest<cr>",
      desc = "Vim test test nearest",
    },
    ["<leader><leader>f"] = {
      function()
        require("telescope").extensions.frecency.frecency {}
      end,
      desc = "Find with frecency"
    }
  },
  i = {
    ["<C-k>"] = {
      function()
        cycle.next()
      end,
      desc = "telescope cycle pickers"
    },
  }
}
