-- local is_ok, configs = pcall(require, "nvim-treesitter.configs")
-- if not is_ok then return end
--
-- configs.setup = {
--   textobjects = {
--     select = {
--       keymaps = {
--         -- outer: outer part
--         -- inner: inner part
--         ["af"] = "@function.outer",
--         ["if"] = "@function.inner",
--         ["ac"] = "@class.outer",
--         ["ic"] = "@class.inner",
--         ["al"] = "@loop.outer",
--         ["il"] = "@loop.inner",
--       },
--       include_surrounding_whitespace = true,
--     },
--   },
-- }
return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  dependencies = "nvim-treesitter/nvim-treesitter",
  config = function()
  end,
}
