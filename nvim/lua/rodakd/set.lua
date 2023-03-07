vim.wo.relativenumber = true
vim.g.mapleader = " "

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50

vim.keymap.set("n", "<leader>pv", function() vim.cmd("Ex") end)
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "<leader>w", function() vim.cmd("w") end)
vim.keymap.set("n", "<leader>d", function() vim.cmd("bd") end)
vim.keymap.set("n", "gh", function() vim.lsp.buf.hover() end)

vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
