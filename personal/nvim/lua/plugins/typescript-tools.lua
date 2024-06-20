return {
  "pmizio/typescript-tools.nvim",
  event = "User AstroFile",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  opts = {},
  confing = function()
    require("typescript-tools").setup({
        -- array of strings("fix_all"|"add_missing_imports"|"remove_unused"|
        -- "remove_unused_imports"|"organize_imports") -- or string "all"
        -- to include all supported code actions
        -- specify commands exposed as code_actions
        settings = {
          expose_as_code_action = {"all"},
        }
    })
  end
}
