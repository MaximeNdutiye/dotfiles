-- All requires are deferred to avoid loading plugins during spec parsing.
-- Only local config modules (config/*) and vim builtins are safe at top level.
local telescope_cycle = require "config/telescope-cycle"
local dev_test_runner = require "config/dev-test-runner"
local telescope_utils = require "config/telescope-utils"
local notify = vim.notify

-- Repeat movement with ; and ,
-- ensure ; goes forward and , goes backward regardless of the last direction
vim.keymap.set({ "n", "x", "o" }, ";", function()
  require("nvim-treesitter-textobjects.repeatable_move").repeat_last_move_next()
end)
vim.keymap.set({ "n", "x", "o" }, ",", function()
  require("nvim-treesitter-textobjects.repeatable_move").repeat_last_move_previous()
end)

-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
vim.keymap.set({ "n", "x", "o" }, "f", function()
  return require("nvim-treesitter-textobjects.repeatable_move").builtin_f_expr()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", function()
  return require("nvim-treesitter-textobjects.repeatable_move").builtin_F_expr()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", function()
  return require("nvim-treesitter-textobjects.repeatable_move").builtin_t_expr()
end, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", function()
  return require("nvim-treesitter-textobjects.repeatable_move").builtin_T_expr()
end, { expr = true })

local cycle = telescope_cycle(
  function()
    local sorter = require("telescope.config").values.file_sorter()
    require("telescope").extensions.frecency.frecency {
      sorter = sorter,
      search_dirs = { vim.fn.finddir(".git/..", vim.fn.expand "%:p:h" .. ";") },
    }
  end,
  function() require("telescope.builtin").find_files() end,
  function() require("telescope.builtin").live_grep() end,
  function() require("telescope.builtin").grep_string() end,
  function() require("telescope.builtin").buffers() end
)

-- Create an autocommand group
local augroup = vim.api.nvim_create_augroup("FindMatchingFile", { clear = true })

-- Create an autocommand that calls find_first_matching_file when a file is opened
-- Maybe allow for configuring this behaviour
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function() dev_test_runner.on_autocommand() end,
  desc = "Find matching test file when opening a file",
})

-- Convert telescope entries to quickfix items
local function telescope_entries_to_qf_items(entries)
  local qf_items = {}
  for _, entry in ipairs(entries) do
    table.insert(qf_items, {
      filename = entry.path,
      lnum = entry.lnum,
      col = 1,
      text = entry.display,
    })
  end
  return qf_items
end

-- Given a log file allows traversing the locations for where the logs were emitted
-- When in a parsed log file file all the
-- code.line_no and code.filepaths and populate the quickfix list
vim.api.nvim_create_user_command("CoreLogs", function()
  local telescope_entries = telescope_utils.toggle_telescope_with_log_file_code_locations()

  if telescope_entries == nil then return notify "No results" end
  if #telescope_entries == 0 then return notify "Empty" end

  local qf_items = telescope_entries_to_qf_items(telescope_entries)
  local namespace = vim.api.nvim_create_namespace "corelogs"
  vim.fn.setqflist(qf_items)
  local log_diagnostics = vim.diagnostic.fromqflist(qf_items)
  vim.diagnostic.set(namespace, 0, log_diagnostics)

  -- vim.cmd("copen")
  vim.cmd [[Trouble qflist open]]
end, {})

return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        -- first key is the mode
        n = {
          -- I want to be able to press 1,2,3,4,5, etc in normal mode to go to the buffer
          ["<Leader>ro"] = {
            function()
              local command = string.format "set_openai_api_key"

              vim.fn.jobstart(command, {
                stdout_buffered = true,
                on_stdout = function(_, data) print(vim.inspect(data)) end,
                on_exit = function(_, exit_code)
                  if exit_code ~= 0 then
                    vim.schedule(function() notify("Exit code not 0", vim.log.levels.ERROR) end)
                  end
                end,
              })
            end,
            desc = "Telescope Resume",
          },
          ["<Leader>tr"] = {
            "<cmd>Telescope resume<cr>",
            desc = "Telescope Resume",
          },
          ["tn"] = {
            "<cmd>TestNearest<cr>",
            desc = "Vim test test nearest",
          },
          ["<A-h>"] = {
            function() require("smart-splits").resize_left() end,
            desc = "Resize split left",
          },
          ["<A-j>"] = {
            function() require("smart-splits").resize_down() end,
            desc = "Resize split down",
          },
          ["<A-k>"] = {
            function() require("smart-splits").resize_up() end,
            desc = "Resize split up",
          },
          ["<A-l>"] = {
            function() require("smart-splits").resize_right() end,
            desc = "Resize split right",
          },
          ["<C-h>"] = {
            function()
              if not telescope_utils.is_telescope_open() then
                require("smart-splits").move_cursor_left()
              else
                cycle.previous()
              end
            end,
            desc = "Move to left split",
          },
          ["<C-j>"] = {
            function() require("smart-splits").move_cursor_down() end,
            desc = "Move to below split or cycle next telescope picker",
          },
          ["<C-k>"] = {
            function() require("smart-splits").move_cursor_up() end,
            desc = "Move to above split",
          },
          ["<C-l>"] = {
            function()
              if not telescope_utils.is_telescope_open() then
                require("smart-splits").move_cursor_right()
              else
                cycle.next()
              end
            end,
            desc = "Move to right split or cycle next telescope picker",
          },
          ["<C-\\>"] = {
            function() require("smart-splits").move_cursor_previous() end,
            desc = "Move to previous split",
          },
          ["<leader><leader>h"] = {
            function() require("smart-splits").swap_buf_left() end,
            desc = "Swap buffer left",
          },
          ["<leader><leader>j"] = {
            function() require("smart-splits").swap_buf_down() end,
            desc = "Swap buffer down",
          },
          ["<leader><leader>k"] = {
            function() require("smart-splits").swap_buf_up() end,
            desc = "Swap buffer up",
          },
          ["<leader><leader>l"] = {
            function() require("smart-splits").swap_buf_right() end,
            desc = "Swap buffer right",
          },
          ["<Leader><Leader>f"] = {
            function() require("telescope").extensions.frecency.frecency {} end,
            desc = "Find with frecency",
          },
          ["<Leader>rt"] = {
            function() dev_test_runner.open_test_or_source_file() end,
            desc = "Find test files (Ruby)",
          },
          ["<Leader>tt"] = {
            "<cmd>ToggleTerm<cr>",
            desc = "Toggle terminal",
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
            desc = "open quick fix window",
          },
          ["<Leader>fg"] = {
            function() require("telescope").extensions.live_grep_args.live_grep_args() end,
            desc = "Telescope live grep with args",
          },
          ["ts"] = {
            "<cmd>Telescope toggleterm_manager<cr>",
            desc = "Toggleterm manager",
          },
          ["<Leader>afe"] = {
            function() vim.g.autoformat = true end,
            desc = "Enable autoformat",
          },
          ["<Leader>afd"] = {
            function() vim.g.autoformat = false end,
            desc = "Disable autoformat",
          },
          -- Git blame (GitLens-like)
          ["<Leader>gb"] = {
            function() require("gitsigns").toggle_current_line_blame() end,
            desc = "Toggle inline git blame",
          },
          ["<Leader>gB"] = {
            function() require("gitsigns").blame_line { full = true } end,
            desc = "Full git blame for current line",
          },
          ["<Leader>gd"] = {
            function() require("gitsigns").diffthis() end,
            desc = "Diff this file",
          },
          ["<Leader>gD"] = {
            function() require("gitsigns").diffthis("~") end,
            desc = "Diff this file against last commit",
          },
          ["<leader>dt"] = {
            function()
              -- Get the current file name
              local filename = vim.fn.expand "%:p"

              notify("Running jest test debug terminal for " .. filename)
              -- Open a terminal and run the Jest debug command
              vim.cmd("term pnpm run test:debug -- " .. filename)

              -- Wait for the Jest process to start and the inspector to be ready
              local timeout = 10 -- Timeout after 10 seconds
              local start_time = vim.fn.reltime()
              local pid = ""

              while vim.fn.reltimefloat(vim.fn.reltime(start_time)) < timeout do
                pid = vim.fn.system("lsof -ti:9229"):gsub("%s+", "") -- Trim whitespace
                if pid ~= "" then break end
                vim.fn.system "sleep 1" -- Sleep for 1 second before checking again
              end

              -- If a PID is found, connect to the debugger
              if pid and pid ~= "" then
                vim.cmd("term node inspect -p " .. pid)
              else
                notify "No process found on port 9229."
              end
            end,
            desc = "Web run jest test in integrated terminal",
          },
        },
        i = {
          ["<C-h>"] = {
            function()
              if not telescope_utils.is_telescope_open() then
                require("smart-splits").move_cursor_left()
              else
                cycle.previous()
              end
            end,
            desc = "Move to left split",
          },
          ["<C-j>"] = {
            function() require("smart-splits").move_cursor_down() end,
            desc = "Move to below split or cycle next telescope picker",
          },
          ["<C-k>"] = {
            function() require("smart-splits").move_cursor_up() end,
            desc = "Move to above split",
          },
          ["<C-l>"] = {
            function()
              if not telescope_utils.is_telescope_open() then
                require("smart-splits").move_cursor_right()
              else
                cycle.next()
              end
            end,
            desc = "Move to right split or cycle next telescope picker",
          },
          ["<C-y>"] = {
            function()
              local telescope_global_state = require "telescope.state"
              local telescope_layout = require "telescope.actions.layout"
              local prompt_bufnrs = telescope_global_state.get_existing_prompt_bufnrs()
              if #prompt_bufnrs == 0 then
                notify "Failed telescope toggle preview. Telescope open?"
                return
              end
              telescope_layout.toggle_preview(prompt_bufnrs[1])
            end,
            desc = "Telescope toggle preview",
          },
        },
        t = {
          ["<esc>"] = {
            [[<C-\><C-n>]],
            desc = "esc to exit term in term mode",
          },
          ["<C-h>"] = {
            function() require("smart-splits").move_cursor_left() end,
            desc = "Move to left split",
          },
          ["<C-j>"] = {
            function() require("smart-splits").move_cursor_down() end,
            desc = "Move to below split",
          },
          ["<C-k>"] = {
            function() require("smart-splits").move_cursor_up() end,
            desc = "Move to above split",
          },
          ["<C-l>"] = {
            function() require("smart-splits").move_cursor_right() end,
            desc = "Move to right split",
          },
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
        },
      },
    },
  },
}
