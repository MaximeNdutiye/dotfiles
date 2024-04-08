return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  -- this prevents copilot from loading
  -- event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = { enabled = false },
      panel = { enabled = false },
      -- Node.js version must be > 18.x
      copilot_node_command = vim.fn.expand("$HOME") .. "/.nvm/versions/node/v20.11.1/bin/node",
    })
  end,
}
