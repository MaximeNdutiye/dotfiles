local ts_repeat_move = require "nvim-treesitter.textobjects.repeatable_move"
local telescope_cycle = require "config/telescope-cycle"
local telescope_builtin = require "telescope.builtin"

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

local cycle = telescope_cycle(
  function()
    local sorter = require 'telescope.config'.values.file_sorter()
    require 'telescope'.extensions.frecency.frecency {
      sorter = sorter,
      search_dirs = { vim.fn.finddir('.git/..', vim.fn.expand('%:p:h') .. ";") }
    }
  end,
  telescope_builtin.find_files,
  telescope_builtin.live_grep,
  telescope_builtin.grep_string,
  telescope_builtin.buffers
)

local function readConfigFile(file)
  if not file then
    return nil
  end

  local configTable = {}
  for line in file:lines() do
    local quotedString = line:match('"([^"]+)"')
    if quotedString then
      table.insert(configTable, quotedString)
    end
  end

  file:close()
  return configTable
end

local shopify_test_search_dirs = readConfigFile(io.open(os.getenv("HOME") .. "/dotfiles/configs/core_tests", "r"))

return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        -- first key is the mode
        n = {
          ["<Leader>tr"] = {
            "<cmd>Telescope resume<cr>",
            desc = "Telescope Resume"
          },
          ["tn"] = {
            "<cmd>TestNearest<cr>",
            desc = "Vim test test nearest",
          },
          ["<Leader><Leader>f"] = {
            function()
              require("telescope").extensions.frecency.frecency {}
            end,
            desc = "Find with frecency"
          },
          ["<Leader>rt"] = {
            function()
              local file_name = vim.fn.expand('%:t:r')
              telescope_builtin.find_files({ default_text = "test/"..file_name, search_dirs = shopify_test_search_dirs })
            end,
            desc = "Find ruby test files in shopify/shopify"
          },
          ["<Leader>tt"] = {
            "<cmd>ToggleTerm<cr>",
            desc = "Toggle terminal"
          },
          ["<Leader>ts"] = {
            "<cmd>TermSelect<cr>",
            desc = "Select terminal"
          },
          ["<Leader>bD"] = {
            function()
              require("astroui.status.heirline").buffer_picker(
                function(bufnr) require("astrocore.buffer").close(bufnr) end
              )
            end,
            desc = "Pick to close",
          },
          ["<Leader>qo"] = {
            "<cmd>copen<cr>",
            desc = "open quick fix window"
          },
          ["<Leader>fg"] = {
            function()
              require("telescope").extensions.live_grep_args.live_grep_args()
            end,
            desc = "Telescope live grep with args"
          },
          ["ts"] = {
            "<cmd>TermSelect<cr>",
            desc  = "Toggleterm term select"
          },
        },
        i = {
          ["<C-k>"] = {
            function()
              cycle.next()
            end,
            desc = "telescope cycle pickers"
          },
        },
        t = {
          ["<esc>"] = {
            [[<C-\><C-n>]],
            desc = "esc to exit term in term mode"
          }
        },
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      mappings = {
        n = {
          -- this mapping will only be set in buffers with an LSP attached
          gl = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" },
          -- a `cond` key can provided as the string of a server capability to be required to attach, or a function with `client` and `bufnr` parameters from the `on_attach` that returns a boolean
          gD = {
            function() vim.lsp.buf.declaration() end,
            desc = "Declaration of current symbol",
            cond = "textDocument/declaration",
          },
          -- ["<Leader>D"] = {
          --   function()
          --     vim.lsp.buf.type_definition()
          --   end,
          --   desc = "Go to type definition"
          -- },
        },
      },
    },
  },
}
