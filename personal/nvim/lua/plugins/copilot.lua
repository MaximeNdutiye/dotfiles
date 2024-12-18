return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  enabled = false,
  -- this prevents copilot from loading
  event = "InsertEnter",
  lazy = true,
  config = function()
    require("copilot").setup({
      suggestion = { enabled = false },
      panel = { enabled = false },
      -- Node.js version must be > 18.x
      copilot_node_command = vim.fn.expand("$HOME") .. "/.nvm/versions/node/v22.2.0/bin/node",
    })
  end,
}
