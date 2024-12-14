return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    -- not sure why this is needed
    -- lazy=false,
    config = function()
      -- require("catppuccin").setup {
      --   flavour = "mocha"
      -- }
    end,
    priority = 1000
  },
}
