return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-neotest/neotest-jest",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "zidhuss/neotest-minitest",
  },
  config = function()
    require("neotest").setup {
      adapters = {
        require "neotest-jest" {
          jestCommand = "npm test --",
          jest_test_discovery = false,
        },
        require "neotest-minitest" {
          test_cmd = function()
            return vim.tbl_flatten {
              "./bin/rails",
              "test",
            }
          end,
        },
      },
      discovery = {
        enabled = false,
      },
    }
  end,
}
