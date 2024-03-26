return {
  "nvim-telescope/telescope.nvim",
  opts = function()
    return {
      defaults = {
        preview = false,
      },
      pickers = {
        find_files = {
          hidden = true
        },
      },
      extensions = {
        frecency = {
          show_unindexed = true,
          ignore_patterns = { "*.git/*", "*/tmp/*" },
          disable_devicons = false,
          auto_validate = true,
          db_validate_threshold = 30,
          workspaces = {
            ["shopify"] = "/Users/maximendutiye/src/github.com/Shopify/shopify",
            ["checkouts"] = "/Users/maximendutiye/src/github.com/Shopify/shopify/components/checkouts",
            ["tcheckouts"] = "/Users/maximendutiye/src/github.com/Shopify/shopify/components/checkouts/test"
          }
        }
      },
    }
  end,
}
