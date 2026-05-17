-- use mason-lspconfig to configure LSP installations
---@type LazySpec
return {
  "mason-org/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "lua_ls",
      "sorbet",
      "eslint",
      "ts_ls",
      "ruby_lsp",
    },
  },
}
