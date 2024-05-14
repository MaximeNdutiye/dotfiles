return {
  'akinsho/toggleterm.nvim',
  opts = {
    insert_mapping = true,
    terminal_mappings = false,
  },
  config = function()
    require("toggleterm").setup(
      {
        shade_terminals = false,
        shading_factor = -3
      }
    )
  end
}
