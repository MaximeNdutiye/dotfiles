local has_words_before = function()
  if vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "prompt" then return false end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match "^%s*$" == nil
end

return {
  "zbirenbaum/copilot-cmp",
  enabled = false,
  dependencies = "copilot.lua",
  lazy = true,
  opts = {
    sources = {
      -- Copilot Source
      { name = "copilot", group_index = 2 },
      -- Other Sources
    },
  },
  config = function(_, opts)
    local copilot_cmp = require "copilot_cmp"
    opts.mappings = {
      ["<Tab>"] = vim.schedule_wrap(function(fallback)
        if copilot_cmp.visible() and has_words_before() then
          copilot_cmp.select_next_item { behavior = copilot_cmp.SelectBehavior.Select }
        else
          fallback()
        end
      end),
    }
    copilot_cmp.setup(opts)
    -- attach cmp source whenever copilot attaches
    -- fixes lazy-loading issues with the copilot cmp source
    vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
    copilot_cmp._on_insert_enter()
  end,
}
