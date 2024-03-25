return {
  "nvim-telescope/telescope.nvim",
  opts = function()
    return {
      defaults = {
        preview = false,
      },
      pickers = {
        find_files = {
          hidden = true
        },
      },
    }
  end,
}
