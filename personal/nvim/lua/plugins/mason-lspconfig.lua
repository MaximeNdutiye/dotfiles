-- use mason-lspconfig to configure LSP installations
---@type LazySpec
return {
  "williamboman/mason-lspconfig.nvim",
  -- overrides `require("mason-lspconfig").setup(...)`
  opts = function(_, opts)
    opts.automatic_installation = true
    -- add more things to the ensure_installed table protecting against community packs modifying it
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      "lua_ls",
      "lua_ls",
      "sorbet",
      "eslint",
      "ts_ls",
      "ruby_lsp",
    })
  end,
}
