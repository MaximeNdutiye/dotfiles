return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
        "nvim-telescope/telescope-live-grep-args.nvim" ,
        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = "^1.0.0",
    },
  },
  opts = function()
    return {
      defaults = {
        preview = false,
        file_ignore_patterns = { ".git/", "/tmp/", "node_modules/", "sorbet/" },
      },
      pickers = {
        find_files = {
          hidden = true
        },
        oldfiles = {
          sort_lastused = true,
          cwd_only = true,
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
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.load_extension("live_grep_args")
    telescope.setup(opts)
  end
}
