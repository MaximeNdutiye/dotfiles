return {
  -- override nvim-cmp plug
  "hrsh7th/nvim-cmp",
  -- override the options table that is used in the `require("cmp").setup()` call
  opts = function(_, opts)
    -- opts parameter is the default options table
    -- the function is lazy loaded so cmp is able to be required
    local cmp = require "cmp"
    local lspkind = require "lspkind"
    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        {
          name = "cmdline",
          option = {
            ignore_cmds = { "Man", "!" },
          },
        },
      }),
    })

    -- modify the sources part of the options table
    opts.sources = cmp.config.sources {
      { name = "copilot", priority = 1000 }, --add copilot
      { name = "nvim_lsp", priority = 1000 },
      { name = "luasnip", priority = 750 },
      { name = "buffer", priority = 500 },
      { name = "fuzzy_buffer", priority = 500 },
      { name = "path", priority = 250 },
      { name = "render-markdown" },
      { name = "lazydev" },
      { name = "dap" },
    }

    vim.api.nvim_create_user_command("CmpSources", function()
      local sources = cmp.get_registered_sources()
      for _, source in ipairs(sources) do
        print(vim.inspect(source["name"]))
      end
      -- print(vim.inspect(cmp.get_registered_sources()))
    end, {})
    -- add copilot icon to lspkind
    opts.formatting = {
      format = lspkind.cmp_format {
        mode = "symbol",
        max_width = 50,
        symbol_map = { Copilot = "" },
      },
    }
    -- return the new table to be used
    return opts
  end,
}
