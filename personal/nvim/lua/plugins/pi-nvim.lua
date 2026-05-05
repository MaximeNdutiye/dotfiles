return {
  dir = vim.fn.stdpath("config") .. "/lua/pi",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = {
    "Pi", "PiSend", "PiNew", "PiSession", "PiKill",
    "PiModels", "PiThinking", "PiCompact", "PiChanges",
    "PiAgents", "PiStats", "PiTerminal", "PiName",
  },
  keys = {
    { "<leader>pi", "<cmd>Pi<cr>", desc = "Toggle Pi chat" },
    { "<leader>ps", "<cmd>PiSession<cr>", desc = "Pi sessions" },
    { "<leader>pm", "<cmd>PiModels<cr>", desc = "Pi models" },
    { "<leader>pa", "<cmd>PiAgents<cr>", desc = "Pi agents" },
    { "<leader>pk", "<cmd>PiKill<cr>", desc = "Kill Pi agent" },
  },
  opts = {
    pi_binary = "pi",
    chat_width = 80,
    auto_scroll = true,
  },
  config = function(_, opts)
    require("pi").setup(opts)
  end,
}
