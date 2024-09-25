-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

vim.cmd.packadd("cfilter")

vim.api.nvim_set_keymap('v', '<C-c>', ':w !pbcopy<CR><CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-c>', '"cyy:let @+=@c<CR>', { noremap = true, silent = true })
table.insert(vim._so_trails, "/?.dylib")

vim.g.clipboard = {
    name = 'spin',
    copy = {
        ['+'] = 'pbcopy',
        ['*'] = 'pbcopy',
    },
    paste = {
        ['+'] = 'pbpaste',
        ['*'] = 'pbpaste',
    },
    cache_enabled = 1,
}

-- Runs asynchronously export OPENAI_API_KEY=$(dev cd openai-proxy && dev generate_token)
-- vim.fn.system({"export", "OPENAI_API_KEY=$(dev cd openai-proxy && dev generate_token)"})
-- os.execute("export OPENAI_API_KEY=$(dev cd openai-proxy && dev generate_token)")

require "lazy_setup"
require "polish"
