require("packer").startup(function(use)
    use("wbthomason/packer.nvim")
    use("neovim/nvim-lspconfig")
    use("nvim-treesitter/nvim-treesitter")
    use("nvim-treesitter/nvim-treesitter-context")
    use("folke/tokyonight.nvim")
    use("mbbill/undotree")
    use("nvim-lua/plenary.nvim")
    use("nvim-telescope/telescope.nvim")
    use("nvim-tree/nvim-web-devicons")
    use("tpope/vim-commentary")
    use("tpope/vim-vinegar")
    use("tpope/vim-fugitive")
    use("hrsh7th/cmp-nvim-lsp")
    use("hrsh7th/cmp-buffer")
    use("hrsh7th/cmp-path")
    use("hrsh7th/cmp-cmdline")
    use("hrsh7th/nvim-cmp")
end)

local cmp = require("cmp")
local treesitter_context = require("treesitter-context")
local treesitter_configs = require("nvim-treesitter.configs")
local telescope = require("telescope")
local telescope_actions = require("telescope.actions")
local telescope_builtin = require("telescope.builtin")
local lspconfig = require("lspconfig")
local nvim_web_devicons = require("nvim-web-devicons")

treesitter_context.setup()
nvim_web_devicons.setup()
lspconfig.clangd.setup {}
lspconfig.tsserver.setup {}
lspconfig.gopls.setup {}
lspconfig.astro.setup {}
-- lspconfig.tailwindcss.setup {}

lspconfig.lua_ls.setup {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' },
            },
        },
    },
}

local prettierFormat = {
    formatCommand = 'prettierd "${INPUT}"',
    formatStdin = true,
}

local sqlFormatterFormat = {
    formatCommand = 'sql-formatter --config ~/.sqlformatterrc',
    formatStdin = true
}

lspconfig.efm.setup {
    init_options = { documentFormatting = true },
    filetypes = {
        "html",
        "css",
        "scss",
        "json",
        "yaml",
        "markdown",
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "sql"
    },
    settings = {
        rootMarkers = { ".git/" },
        languages = {
            html = { prettierFormat },
            css = { prettierFormat },
            scss = { prettierFormat },
            json = { prettierFormat },
            yaml = { prettierFormat },
            markdown = { prettierFormat },
            javascript = { prettierFormat },
            typescript = { prettierFormat },
            javascriptreact = { prettierFormat },
            typescriptreact = { prettierFormat },
            sql = { sqlFormatterFormat },
        }
    }
}

treesitter_configs.setup({
    ensure_installed = { "c", "typescript", "javascript", "python", "go", "bash", "lua" },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
    },
    autotag = {
        enable = true,
    },
    context_commentstring = {
        enable = true,
    },
})

cmp.setup({
    mapping = cmp.mapping.preset.insert({
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
    sources = {
        { name = "nvim_lsp" },
    },
})

cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = "buffer" },
    },
})

cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = "path" },
    }, {
        { name = "cmdline" },
    }),
})

telescope.setup({
    defaults = {
        layout_strategy = "vertical",
        layout_config = {
            height = 0.99,
            preview_cutoff = 10,
            prompt_position = "bottom",
            width = 0.99,
        },
        mappings = {
            i = {
                ["<esc>"] = telescope_actions.close,
            },
        },
    },
})

vim.g.mapleader = " "
vim.g.netrw_bufsettings = "noma nomod nu nobl nowrap ro"
vim.g.netrw_keepdir = 0
vim.o.ruler = false
vim.o.laststatus = 0
vim.opt.signcolumn = "no"
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = false
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.isfname:append("@-@")
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

vim.cmd("colorscheme tokyonight-storm")
vim.cmd("autocmd BufRead,BufNewFile Jenkinsfile set filetype=groovy")
vim.cmd('autocmd BufEnter * call system("tmux rename-window " . expand("%"))')
vim.cmd('autocmd VimLeave * call system("tmux rename-window zsh")')
vim.cmd("autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>")
vim.cmd("hi NormalNC ctermbg=NONE guibg=NONE")
vim.cmd("hi Normal ctermbg=NONE guibg=NONE")
vim.cmd("hi CursorLine guibg='#2A3454'")
vim.cmd("hi LineNr guifg='#888888'")
vim.cmd("hi CursorLineNr guifg='#87afff'")
vim.cmd("hi TelescopeNormal cterm=NONE guibg=NONE")
vim.cmd("hi TelescopeBorder cterm=NONE guibg=NONE guifg='#87afff'")
vim.cmd("nnoremap <C-i> :b# <CR>")
vim.cmd("nnoremap <C-l> <C-o>")

vim.cmd([[
if has("persistent_undo")
    let target_path = expand('~/.undodir')

    if !isdirectory(target_path)
        call mkdir(target_path, "p", 0700)
    endif

    let &undodir=target_path
    set undofile
endif
]])

vim.keymap.set("n", "<C-s>", telescope_builtin.git_status, {})
vim.keymap.set("n", "<C-p>", telescope_builtin.git_files, {})
vim.keymap.set("n", "<C-o>", telescope_builtin.oldfiles, {})
vim.keymap.set("n", "<C-f>", telescope_builtin.live_grep, {})
vim.keymap.set("n", "<C-h>", telescope_builtin.help_tags, {})
vim.keymap.set("n", "<C-y>", telescope_builtin.resume, {})
vim.keymap.set("n", "<leader>w", vim.cmd.w, {})
vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<leader>Y", function()
    vim.cmd(':let @+ = expand("%")')
end, {})

vim.keymap.set("n", "<C-t>", function()
    vim.cmd("UndotreeToggle")
    vim.cmd("UndotreeFocus")
end)

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),

    callback = function(ev)
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        vim.keymap.set("n", "gr", function()
            telescope_builtin.lsp_references({ trim_text = true, show_line = false })
        end, opts)

        vim.keymap.set({ "n", "v" }, "L", function()
            vim.diagnostic.open_float(0, { scope = "line" })
        end, opts)

        vim.keymap.set("n", "<C-b>", function()
            telescope_builtin.diagnostics({
                severity = "error",
            })
        end, opts)

        vim.keymap.set("n", "<C-m>", function()
            vim.diagnostic.goto_next({ float = false, severity = "error" })
        end, opts)

        vim.keymap.set('n', '<space>w', function()
            vim.lsp.buf.format {
                filter = function(client) return client.name ~= "tsserver" end
            }
            vim.cmd.w()
        end, opts)
    end,
})

vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = false,
    })
