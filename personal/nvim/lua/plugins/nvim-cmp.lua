return {
  -- override nvim-cmp plug
  "hrsh7th/nvim-cmp",
  -- override the options table that is used in the `require("cmp").setup()` call
  opts = function(_, opts)
    -- opts parameter is the default options table
    -- the function is lazy loaded so cmp is able to be required
    local cmp = require "cmp"
    local lspkind = require("lspkind")

    -- modify the sources part of the options table
    opts.sources = cmp.config.sources {
      { name = "copilot",  group_index = 2 }, --add copilot
      { name = "nvim_lsp", priority = 1000 },
      { name = "luasnip",  priority = 750 },
      { name = "buffer",   priority = 500 },
      { name = "path",     priority = 250 },
    }

    -- add copilot icon to lspkind
    opts.formatting = {
      format = lspkind.cmp_format({
        mode = "symbol",
        max_width = 50,
        symbol_map = { Copilot = "" }
      })
    }
    -- return the new table to be used
    return opts
  end,
}
