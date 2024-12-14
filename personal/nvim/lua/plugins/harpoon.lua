return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function(_)
    local harpoon = require "harpoon"
    harpoon:setup {
      ---@class HarpoonSettings
      settings = {
        save_on_toggle = false,
        sync_on_ui_close = false,
      },
    }
  end,
}
