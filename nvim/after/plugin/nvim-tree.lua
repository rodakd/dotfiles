vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require("nvim-tree").setup()

local api = require("nvim-tree.api")

vim.keymap.set('n', '<C-e>', api.tree.open, {})
