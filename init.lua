local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end

vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
	"tpope/vim-sleuth",
	"nvim-treesitter/nvim-treesitter",
	"nvim-lua/plenary.nvim",
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && cmake --build build --config Release",
	},
	"nvim-telescope/telescope.nvim",
	"nvim-tree/nvim-web-devicons",
	"stevearc/oil.nvim",
	"nvim-pack/nvim-spectre",
	"JoosepAlviste/nvim-ts-context-commentstring",
	"stevearc/conform.nvim",
	"nvim-telescope/telescope-ui-select.nvim",
	"echasnovski/mini.nvim",
	"nvim-lualine/lualine.nvim",
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
})

local treesitter_configs = require("nvim-treesitter.configs")
local telescope = require("telescope")
local telescope_actions = require("telescope.actions")
local telescope_builtin = require("telescope.builtin")
local nvim_web_devicons = require("nvim-web-devicons")
local oil = require("oil")
local spectre = require("spectre")
local conform = require("conform")
local mini_comment = require("mini.comment")
local catppuccin = require("catppuccin")
local lualine = require("lualine")

lualine.setup()

catppuccin.setup({
	auto_integrations = true,
})

conform.setup({
	notify_on_error = false,

	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettierd" },
		json = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescript = { "prettierd" },
		typescriptreact = { "prettierd" },
	},

	format_after_save = {
		lsp_format = "fallback",
	},
})

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

mini_comment.setup({
	options = {
		custom_commentstring = function()
			return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
		end,
	},
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

nvim_web_devicons.setup()

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
vim.opt.ruler = false
vim.opt.signcolumn = "yes"
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.guicursor = "n-v-c-i:block"
vim.opt.cursorline = false
vim.opt.scrolloff = 8
vim.o.updatetime = 300
vim.o.winborder = "rounded"
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

		vim.keymap.set("n", "gH", telescope_builtin.highlights, opts)
		vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, opts)
		vim.keymap.set("n", "gt", telescope_builtin.lsp_type_definitions, opts)
		vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, opts)
		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover({
				border = "rounded",
			})
		end, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

		vim.keymap.set("n", "gR", function()
			telescope_builtin.lsp_references({ trim_text = true, show_line = false, buffer = ev.buf })
		end, opts)

		vim.keymap.set({ "n", "v" }, "L", function()
			vim.diagnostic.open_float(0, { scope = "line" })
		end, opts)

		vim.keymap.set("n", "<C-m>", function()
			vim.diagnostic.goto_next()
		end, opts)

		vim.keymap.set("n", "<leader>w", function()
			vim.cmd.wall({ bang = true })
		end, opts)
	end,
})

vim.cmd("colorscheme catppuccin-mocha")
local colors = require("catppuccin.palettes").get_palette()

local theme = {
	TelescopeMatching = { fg = colors.flamingo },
	TelescopeSelection = { fg = colors.text, bg = colors.surface0, bold = true },
	TelescopePromptPrefix = { bg = colors.base },
	TelescopePromptNormal = { bg = colors.base },
	TelescopeResultsNormal = { bg = colors.base },
	TelescopePreviewNormal = { bg = colors.base },
	TelescopePromptBorder = { bg = colors.base, fg = colors.pink },
	TelescopeResultsBorder = { bg = colors.base, fg = colors.pink },
	TelescopePreviewBorder = { bg = colors.base, fg = colors.pink },
	TelescopePromptTitle = { bg = colors.base, fg = colors.pink },
	TelescopeResultsTitle = { bg = colors.base, fg = colors.pink },
	TelescopePreviewTitle = { bg = colors.base, fg = colors.pink },
	CmpBorder = { fg = "#89b4fb" },
	CmpDocBorder = { fg = "#89b4fb" },
	FloatBorder = { fg = "#89b4fb", bg = nil },
}

for hl, col in pairs(theme) do
	vim.api.nvim_set_hl(0, hl, col)
end

vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
