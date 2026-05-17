-- Migrated from nvim-cmp to blink.cmp (AstroNvim v6)
return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
      },
      cmdline = {
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == "/" or type == "?" then return { "buffer" } end
          if type == ":" then return { "cmdline", "path" } end
          return {}
        end,
      },
    },
  },
}
