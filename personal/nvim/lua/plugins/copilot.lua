return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  enabled = false,
  -- this prevents copilot from loading
  event = "InsertEnter",
  lazy = true,
  config = function()
    -- _G.copilot_no_tab_map = true
    -- _G.copilot_assume_mapped = true
    -- _G.copilot_tab_fallback = ""
    -- The mapping is set to other key, see custom/lua/mappings
    -- or run <leader>ch to see copilot mapping section

    require("copilot").setup {
      suggestion = { enabled = false },
      panel = { enabled = false },
      -- Node.js version must be > 18.x
      copilot_node_command = vim.fn.expand "$HOME" .. "/.nvm/versions/node/v22.2.0/bin/node",
      server_opts_overrides = {
        trace = "verbose",
        settings = {
          advanced = {
            listCount = 10, -- #completions for panel
            inlineSuggestCount = 3, -- #completions for getCompletions
          },
        },
      },
    }
  end,
}
