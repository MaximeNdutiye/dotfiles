return {
  n = {
    ["<leader>ca"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      desc = "Code Action",
    },
    ["<leader>tr"] = {
      "<cmd>Telescope resume",
      desc = "Telescope Resume"
    }
  },
}
