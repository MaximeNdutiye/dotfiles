return {
  "f-person/auto-dark-mode.nvim",
  lazy = false,
  opts = {
    update_interval = 1000,
    set_dark_mode = function()
      vim.cmd("colorscheme catppuccin-mocha")
      vim.cmd("set background=dark")
    end,
    set_light_mode = function()
      vim.cmd("colorscheme catppuccin-latte")
      vim.cmd("set background=light")
    end,
  },
}
