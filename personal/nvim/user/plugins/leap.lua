return {
  "ggandor/leap.nvim",
  lazy = false,
  config = function(_, opts)
    local leap = require("leap")
    leap.add_default_mappings(true)
  end,
}
