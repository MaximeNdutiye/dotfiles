return {
  "windwp/nvim-autopairs",
  config = function(plugin, opts)
    require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
  end,
}
