-- Plugin
require("packer").startup(function(use)
	use("wbthomason/packer.nvim")
	use("folke/tokyonight.nvim")
	use("tpope/vim-commentary")
	use("neovim/nvim-lspconfig")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/nvim-cmp")
	use("saadparwaiz1/cmp_luasnip")
	use("L3MON4D3/LuaSnip")
	use("nvim-lua/plenary.nvim")
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})
	use({ "nvim-telescope/telescope.nvim" })
	use({
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({})
		end,
	})
	use("tpope/vim-fugitive")
	use("williamboman/mason.nvim")
	use("williamboman/mason-lspconfig.nvim")
	use("jose-elias-alvarez/null-ls.nvim")
	use("jay-babu/mason-null-ls.nvim")
	use("windwp/nvim-ts-autotag")
	use("tpope/vim-repeat")
	use("nvim-pack/nvim-spectre")
	use("nvim-tree/nvim-web-devicons")
	use("JoosepAlviste/nvim-ts-context-commentstring")
	use("windwp/nvim-autopairs")
	use("tpope/vim-surround")
	use("mbbill/undotree")
	use("maxmellon/vim-jsx-pretty")
	use("nvim-treesitter/nvim-treesitter-context")
	use("tpope/vim-vinegar")
end)

require("nvim-autopairs").setup({
	disable_filetype = { "TelescopePrompt", "vim" },
})
require("treesitter-context").setup()
require("nvim-web-devicons").setup()
require("nvim-treesitter.configs").setup({
	ensure_installed = "all",
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

local luasnip = require("luasnip")
local cmp = require("cmp")

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
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
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = {
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
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

local actions = require("telescope.actions")
local telescopeb = require("telescope.builtin")
require("telescope").setup({
	defaults = {
		layout_strategy = "horizontal",
		layout_config = {
			height = 0.95,
			width = 0.95,
			preview_width = 0.5,
		},
		mappings = {
			i = {
				["<esc>"] = actions.close,
			},
		},
	},
})

require("mason").setup()
require("mason-lspconfig").setup()
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")
require("mason-lspconfig").setup_handlers({
	function(server_name)
		lspconfig[server_name].setup({
			capabilities = capabilities,
		})
	end,
	["lua_ls"] = function()
		lspconfig.lua_ls.setup({
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})
	end,
})
require("mason-null-ls").setup({
	automatic_installation = false,
	handlers = {},
})

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local null_ls = require("null-ls")
local lSsources = {
	null_ls.builtins.formatting.prettierd.with({
		filetypes = {
			"typescript",
			"typescriptreact",
			"javascript",
			"css",
			"scss",
			"html",
			"json",
			"yaml",
			"markdown",
			"md",
			"txt",
			"astro",
		},
	}),
}

null_ls.setup({
	sources = lSsources,
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({
						bufnr = bufnr,
						filter = function(c)
							return c.name == "null-ls"
						end,
						async = false,
					})
				end,
			})
		end
	end,
})

vim.cmd([[
if has("persistent_undo")
   let target_path = expand('~/.undodir')

    " create the directory and any parent directories
    " if the location does not exist.
    if !isdirectory(target_path)
        call mkdir(target_path, "p", 0700)
    endif

    let &undodir=target_path
    set undofile
endif
]])

-- Defaults
vim.opt.signcolumn = "no"
vim.o.ruler = false
vim.o.laststatus = 0
vim.g.mapleader = " "
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = false
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
		local opts = { buffer = ev.buf }
		vim.keymap.set("n", "gr", function()
			telescopeb.lsp_references({ trim_text = true, show_line = false })
		end, opts)
		vim.keymap.set("n", "gd", telescopeb.lsp_definitions, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set({ "n", "v" }, "L", function()
			vim.diagnostic.open_float(0, { scope = "line" })
		end, opts)
		vim.keymap.set("n", "<C-b>", function()
			telescopeb.diagnostics()
		end, {})
		vim.keymap.set("n", "<C-m>", function()
			vim.diagnostic.goto_next({ float = false })
		end, {})
	end,
})

-- Indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Netrw
vim.g.netrw_bufsettings = "noma nomod nu nobl nowrap ro"
vim.g.netrw_keepdir = 0

-- Colorscheme
vim.cmd("colorscheme tokyonight-night")
vim.cmd("hi NormalNC ctermbg=NONE guibg=NONE")
vim.cmd("hi Normal ctermbg=NONE guibg=NONE")
vim.cmd("autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>")
vim.cmd("hi CursorLine guibg='#2A3454'")
vim.cmd("hi LineNr guifg='#888888'")
vim.cmd("hi CursorLineNr guifg='#87afff'")
vim.cmd("hi TelescopeNormal cterm=NONE guibg=NONE")
vim.cmd("hi TelescopeBorder cterm=NONE guibg=NONE guifg='#87afff'")

-- Tmux
vim.cmd('autocmd BufEnter * call system("tmux rename-window " . expand("%"))')
vim.cmd('autocmd VimLeave * call system("tmux rename-window zsh")')

-- Keymaps
vim.keymap.set("n", "<C-s>", telescopeb.git_status, {})
vim.keymap.set("n", "<C-p>", telescopeb.git_files, {})
vim.keymap.set("n", "<C-o>", telescopeb.oldfiles, {})
vim.keymap.set("n", "<C-f>", telescopeb.live_grep, {})
vim.keymap.set("n", "<C-h>", telescopeb.help_tags, {})
vim.keymap.set("n", "<C-y>", telescopeb.resume, {})
vim.keymap.set("n", "<leader>Y", function()
	vim.cmd(':let @+ = expand("%")')
end, {})
vim.keymap.set("n", "<C-g>", function()
	vim.cmd("G")
end)
vim.keymap.set("n", "<C-t>", function()
	vim.cmd("UndotreeToggle")
	vim.cmd("UndotreeFocus")
end)
vim.keymap.set("n", "<leader>w", vim.cmd.w, {})
vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.cmd("nnoremap <C-i> :b# <CR>")
vim.cmd("nnoremap <C-l> <C-o>")

-- Filter diagnostics
local ignore = {
	["Pyright"] = {
		'^".+" is unknown import symbol$',
	},
}

function Filter(arr, func)
	local new_index = 1
	local size_orig = #arr
	for old_index, v in ipairs(arr) do
		if func(v, old_index) then
			arr[new_index] = v
			new_index = new_index + 1
		end
	end
	for i = new_index, size_orig do
		arr[i] = nil
	end
end

function Filter_diagnostics(diagnostic)
	for source, messages in pairs(ignore) do
		if source == diagnostic.source then
			for i, message in ipairs(messages) do
				if string.match(diagnostic.message, message) then
					return false
				end
			end
		end
	end
	return true
end

function Custom_on_publish_diagnostics(a, params, client_id, c, config)
	Filter(params.diagnostics, Filter_diagnostics)
	vim.lsp.diagnostic.on_publish_diagnostics(a, params, client_id, c, config)
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(Custom_on_publish_diagnostics, {
	update_in_insert = true,
	underline = false,
})

-- Snippets
-- You can check file type with
-- print(vim.inspect(require("luasnip").get_snippet_filetypes()))`)
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function copy(args)
	return args[1]
end

ls.add_snippets("all", {}, { key = "all" })

ls.add_snippets("python", {
	s("def", {
		t("def "),
		i(1, "name"),
		t("("),
		i(2, "args"),
		t({ "):", "\t" }),
		i(3, "pass"),
	}),
}, {
	key = "python",
})

ls.add_snippets("typescript", {
	s("cl", {
		t({ "console.log(`", "\t", "" }),
		i(1),
		t({ "", "", "`)" }),
	}),
}, {
	key = "typescript",
})

ls.filetype_extend("typescriptreact", { "typescript" })
ls.add_snippets("typescriptreact", {
	s("rfc", {
		t("type "),
		f(copy, 1),
		t({ "Props = {}", "", "export function " }),
		i(1, "Component"),
		t("({}: "),
		f(copy, 1),
		t({ "Props) {", "\t" }),
		i(2, "return"),
		t({ "", "}", "" }),
	}),
}, {
	key = "typescriptreact",
})
