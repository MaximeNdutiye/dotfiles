return {
  'akinsho/toggleterm.nvim',
  opts = {
    insert_mapping = true,
    terminal_mappings = false,
  },
  config = function()
    require("toggleterm").setup()
  end
}
