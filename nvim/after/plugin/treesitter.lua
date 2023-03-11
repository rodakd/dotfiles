require 'nvim-treesitter.configs'.setup {
    ensure_installed = { "help", "javascript", "typescript", "c", "lua", "rust" },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    autopairs = {
        enable = true,
    },
    context_commentstring = {
        enable = true,
        enable_autocmd = false,
    },
}
