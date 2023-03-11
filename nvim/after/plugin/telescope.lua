local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

vim.keymap.set('n', '<leader>gc', builtin.git_commits, {})
vim.keymap.set('n', '<leader>gf', builtin.git_bcommits, {})
vim.keymap.set('n', '<leader>gb', builtin.git_branches, {})
vim.keymap.set('n', '<leader>gs', builtin.git_status, {})

vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<C-o>', builtin.oldfiles, {})
vim.keymap.set('n', '<C-f>', builtin.live_grep, {})

local transform_mod = require('telescope.actions.mt').transform_mod
local actions = require('telescope.actions')
local mod = {}
mod.open_in_nvim_tree = function()
    local cur_win = vim.api.nvim_get_current_win()
    vim.cmd("NvimTreeFindFile")
    pcall(function() vim.api.nvim_set_current_win(cur_win) end)
end

mod = transform_mod(mod)

require("telescope").setup {
    defaults = {
        mappings = {
            i = {
                ["<CR>"] = actions.select_default + mod.open_in_nvim_tree,
            },
            n = {
                ["<CR>"] = actions.select_default + mod.open_in_nvim_tree,
            },
        },
    },
}
