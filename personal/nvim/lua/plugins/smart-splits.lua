return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  config = function(opts)
    opts.at_edge = 'stop'
    require('smart-splits').setup(opts)
  end
}
