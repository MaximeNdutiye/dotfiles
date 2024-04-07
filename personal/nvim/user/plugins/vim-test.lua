local g = vim.g

g["test#strategy"] = "toggleterm"

return {
  "vim-test/vim-test",
  event = "User AstroFile",
}
