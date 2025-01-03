return {
  "zbirenbaum/copilot-cmp",
  enabled = false,
  dependencies = "copilot.lua",
  lazy = true,
  opts = {
    sources = {
      -- Copilot Source
      { name = "copilot", group_index = 2 },
      -- Other Sources
    },
  },
  config = function(_, opts)
    local copilot_cmp = require("copilot_cmp")
    copilot_cmp.setup(opts)
    -- attach cmp source whenever copilot attaches
    -- fixes lazy-loading issues with the copilot cmp source
    copilot_cmp._on_insert_enter()
  end,
}
