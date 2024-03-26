return {
  "ggandor/leap.nvim",
  event = "User AstroFile",
  config = function(_, _opts)
    local leap = require("leap")
    leap.add_default_mappings(true)
  end,
}
