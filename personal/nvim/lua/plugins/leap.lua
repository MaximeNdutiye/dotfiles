return {
  "ggandor/leap.nvim",
  event = "User AstroFile",
  enabled = false,
  config = function(_, _)
    local leap = require("leap")
    leap.add_default_mappings(true)
  end,
}
