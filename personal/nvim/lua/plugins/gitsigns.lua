return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true, -- show blame inline like GitLens
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
      delay = 300, -- ms delay before blame appears
      ignore_whitespace = true,
    },
    current_line_blame_formatter = "  <author>, <author_time:%R> • <summary>",
  },
}
