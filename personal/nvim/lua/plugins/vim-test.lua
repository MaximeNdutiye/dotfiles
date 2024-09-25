local g = vim.g

g["test#strategy"] = "toggleterm"

g["test#javascript#runner"] = "jest"

return {
  "vim-test/vim-test",
  event = "User AstroFile",
}
