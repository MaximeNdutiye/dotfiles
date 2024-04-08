return {
  "nvim-lspconfig",
  event = { 'BufReadPre', 'BufReadPost', 'BufNewFile' },
  config = function()
    local lspconfig = require('lspconfig')
    local ruby_ls = require("config/ruby_ls")

    lspconfig.ruby_ls.setup({
      on_attach = function(client, buffer)
        if ruby_ls.setup_diagnostics ~= nil and ruby_ls.add_ruby_deps_command ~= nil then
          ruby_ls.setup_diagnostics(client, buffer)
          ruby_ls.add_ruby_deps_command(client, buffer)
        end
      end,
    })
  end
}
