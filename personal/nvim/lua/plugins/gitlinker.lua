return {
  'ruifm/gitlinker.nvim',
  dependencies = 'nvim-lua/plenary.nvim',
  event = "User AstroFile",
  config = function()
    require "gitlinker".setup()
  end
}
