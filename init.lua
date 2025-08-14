local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	"tpope/vim-sleuth",
	"neovim/nvim-lspconfig",
	"nvim-treesitter/nvim-treesitter",
	"nvim-lua/plenary.nvim",
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
	},
	"nvim-telescope/telescope.nvim",
	"nvim-tree/nvim-web-devicons",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"hrsh7th/nvim-cmp",
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
	"stevearc/oil.nvim",
	"nvim-pack/nvim-spectre",
	"nordtheme/vim",
	"nvim-treesitter/nvim-treesitter-context",
	"JoosepAlviste/nvim-ts-context-commentstring",
	"f-person/git-blame.nvim",
	"stevearc/conform.nvim",
	"nvim-telescope/telescope-ui-select.nvim",
	"echasnovski/mini.nvim",
})

local cmp = require("cmp")
local treesitter_configs = require("nvim-treesitter.configs")
local telescope = require("telescope")
local telescope_actions = require("telescope.actions")
local telescope_builtin = require("telescope.builtin")
local lspconfig = require("lspconfig")
local nvim_web_devicons = require("nvim-web-devicons")
local luasnip = require("luasnip")
local oil = require("oil")
local treesitter_context = require("treesitter-context")
local spectre = require("spectre")
local gitblame = require("gitblame")
local conform = require("conform")
local mini_surround = require("mini.surround")
local mini_comment = require("mini.comment")

mini_surround.setup()

mini_comment.setup({
	options = {
		custom_commentstring = function()
			return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
		end,
	},
})

conform.setup({
	notify_on_error = false,
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "black" },
		javascript = { "prettierd" },
		json = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescript = { "prettierd" },
		typescriptreact = { "prettierd" },
		odin = { "odinfmt" },
	},
	formatters = {
		odinfmt = {
			command = "odinfmt",
			args = { "-stdin" },
			stdin = true,
		},
	},
	format_after_save = {
		lsp_format = "fallback",
	},
})

gitblame.setup({ enabled = false, date_format = "%d-%m-%Y %H:%M:%S" })

spectre.setup({
	replace_engine = {
		["sed"] = {
			cmd = "sed",
			args = {
				"-i",
				"",
				"-E",
			},
		},
	},
})

treesitter_context.setup({
	multiline_threshold = 1,
})

oil.setup({
	keymaps = {
		["<C-p>"] = false,
		["<C-s>"] = false,
	},

	view_options = {
		show_hidden = true,
	},

	skip_confirm_for_simple_edits = true,
})

local cmp_window = cmp.config.window.bordered({
	winhighlight = "Normal:Normal,FloatBorder:BorderBG,CursorLine:PmenuSel,Search:None",
	scrollbar = false,
})

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
		}),
	}),

	window = {
		completion = cmp_window,
		documentation = cmp_window,
	},

	sources = {
		{ name = "nvim_lsp", max_item_count = 10 },
		{ name = "luasnip", max_item_count = 10 },
		{ name = "buffer", max_item_count = 2 },
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

local capabilities = require("cmp_nvim_lsp").default_capabilities()
nvim_web_devicons.setup()

lspconfig.html.setup({
	capabilities = capabilities,
})

lspconfig.pyright.setup({
	capabilities = capabilities,
})

lspconfig.vtsls.setup({
	capabilities = capabilities,

	initialization_options = {
		typescript = {
			tsserver = {
				maxTsServerMemory = 4096,
			},
		},
	},
})

lspconfig.clangd.setup({
	capabilities = capabilities,
})

lspconfig.ols.setup({
	capabilities = capabilities,
	init_options = {
		enable_references = true,
	},
})

lspconfig.gopls.setup({
	capabilities = capabilities,
})

lspconfig.jsonls.setup({
	capabilities = capabilities,

	init_options = {
		provideFormatter = false,
	},
})

lspconfig.cssls.setup({
	capabilities = capabilities,

	init_options = {
		provideFormatter = false,
	},
})

lspconfig.html.setup({
	capabilities = capabilities,
})

lspconfig.lua_ls.setup({
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "love" },
			},
		},
	},

	capabilities = capabilities,
})

local MAX_TS_FILE_SIZE = 300 * 1024

treesitter_configs.setup({
	sync_install = false,
	auto_install = true,

	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
		use_languagetree = false,

		disable = function(_, bufnr)
			local buf_name = vim.api.nvim_buf_get_name(bufnr)
			local file_size = vim.api.nvim_call_function("getfsize", { buf_name })
			return file_size > MAX_TS_FILE_SIZE
		end,
	},
})

telescope.setup({
	defaults = {
		vimgrep_arguments = {
			"rg",
			"--color=never",
			"--no-heading",
			"--with-filename",
			"--line-number",
			"--column",
			"--smart-case",
			"--fixed-strings",
		},

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

		preview = {
			filesize_limit = 0.3,
			highlight_limit = 1,
		},
	},

	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown({}),
		},
	},
})

telescope.load_extension("ui-select")
telescope.load_extension("fzf")
vim.cmd("colorscheme nord")
vim.cmd("hi Visual ctermfg=none ctermbg=0 guibg=#434c5e")
vim.g.mapleader = " "
vim.opt.ruler = false
vim.opt.signcolumn = "no"
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = false
vim.opt.guicursor = "n-v-c-i:block"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.o.updatetime = 300
vim.opt.isfname:append("@-@")
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.showmode = false
vim.opt.laststatus = 0

vim.cmd("autocmd BufRead,BufNewFile Jenkinsfile* set filetype=groovy")
vim.cmd("autocmd BufEnter set filetype=groovy")
vim.cmd("autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>")
vim.cmd("nnoremap <C-i> <Tab> <CR>")
vim.cmd("nnoremap <C-l> <C-o>")

vim.cmd(
	"autocmd BufRead,BufNewFile */templates/*.{yaml,yml},*/templates/*.tpl,*.gotmpl,helmfile*.{yaml,yml} set ft=helm"
)

vim.keymap.set("n", "<C-b>", telescope_builtin.diagnostics, {})
vim.keymap.set("n", "<C-s>", telescope_builtin.git_status, {})
vim.keymap.set("n", "<C-p>", telescope_builtin.git_files, {})
vim.keymap.set("n", "<C-o>", telescope_builtin.oldfiles, {})
vim.keymap.set("n", "<C-f>", telescope_builtin.live_grep, {})
vim.keymap.set("n", "<C-h>", telescope_builtin.help_tags, {})
vim.keymap.set("n", "<C-y>", telescope_builtin.resume, {})
vim.keymap.set("n", "<leader>w", vim.cmd.w, {})
vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "-", "<CMD>Oil<CR>", {})

vim.keymap.set("n", "<leader>Y", function()
	vim.cmd(':let @+ = expand("%:p")')
end, {})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),

	callback = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
		local opts = { buffer = ev.buf }
		local bufName = vim.api.nvim_buf_get_name(ev.buf)
		local isGo = bufName:sub(-#".go") == ".go"
		local isTypescript = bufName:sub(-#".ts") == ".ts" or bufName:sub(-#".tsx") == ".tsx"

		vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, opts)
		vim.keymap.set("n", "gt", telescope_builtin.lsp_type_definitions, opts)
		vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

		vim.keymap.set("n", "gR", function()
			telescope_builtin.lsp_references({ trim_text = true, show_line = false, buffer = ev.buf })
		end, opts)

		vim.keymap.set({ "n", "v" }, "L", function()
			vim.diagnostic.open_float(0, { scope = "line" })
		end, opts)

		vim.keymap.set("n", "<C-m>", function()
			vim.diagnostic.goto_next({ float = false, severity = "error" })
		end, opts)

		vim.keymap.set("n", "<leader>w", function()
			if isGo then
				local params = vim.lsp.util.make_range_params()
				params.context = { only = { "source.organizeImports" } }
				local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
				for cid, res in pairs(result or {}) do
					for _, r in pairs(res.result or {}) do
						if r.edit then
							local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
							vim.lsp.util.apply_workspace_edit(r.edit, enc)
						end
					end
				end
			end

			vim.cmd.wall({ bang = true })
		end, opts)

		if isGo then
			vim.keymap.set("n", "<leader>ee", "o<Enter>if err != nil {<CR>}<Esc>Oreturn err<Esc>", opts)
		end

		if isTypescript then
			vim.keymap.set("n", "<leader>cl", "oconsole.log('\\n\\n\\n <ESC>pa', <ESC>pa, '\\n\\n\\n')<Esc>", opts)

			vim.keymap.set(
				"n",
				"<leader>cmp",
				"aimport * as React from 'react'<CR><CR>type Props = {}<CR><CR>function <Esc>pa({}: Props) {<CR>return (<CR><div><Esc>pa</div><CR>)<CR>}<Esc>",
				opts
			)

			vim.keymap.set("n", "<leader>ct", "oimport * as t from 'common/types'<Esc>", opts)
		end
	end,
})
