return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy=false,
    config = function()
      require("catppuccin").setup {
        flavour = "mocha"
      }
    end,
    priority = 1000
  },
}
