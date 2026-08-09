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
	"neovim/nvim-lspconfig",
	"nvim-lua/plenary.nvim",
	"nvim-telescope/telescope.nvim",
	"nvim-tree/nvim-web-devicons",
	"stevearc/oil.nvim",
	"nvim-pack/nvim-spectre",
	"stevearc/conform.nvim",
	"dstein64/nvim-scrollview",
	"MeanderingProgrammer/render-markdown.nvim",
	"nvim-treesitter/nvim-treesitter-context",
	{ "ellisonleao/gruvbox.nvim", priority = 1000, config = true, opts = ... },
	{
		"saghen/blink.cmp",
		version = "1.*",

		opts = {
			keymap = { preset = "enter", ["<C-e>"] = { "show", "show_documentation", "hide_documentation" } },
			completion = {
				list = {
					selection = {
						preselect = false,
					},
				},
			},
		},

		opts_extend = { "sources.default" },
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local treesitter = require("nvim-treesitter")
					local lang = vim.treesitter.language.get_lang(args.match)
					if not lang then
						return
					end
					local available = treesitter.get_available()
					if not vim.tbl_contains(available, lang) then
						return
					end
					local installed = treesitter.get_installed()
					if not vim.tbl_contains(installed, lang) then
						treesitter.install(lang):wait()
					end
					vim.treesitter.start()
				end,
			})
		end,
	},
})

local telescope = require("telescope")
local telescope_actions = require("telescope.actions")
local telescope_builtin = require("telescope.builtin")
local nvim_web_devicons = require("nvim-web-devicons")
local oil = require("oil")
local spectre = require("spectre")
local conform = require("conform")
local scrollview = require("scrollview")
local treesitter_context = require("treesitter-context")

treesitter_context.setup()
scrollview.setup()

conform.setup({
	notify_on_error = false,

	format_on_save = {
		lsp_format = "fallback",
	},

	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettierd" },
		json = { "prettierd" },
		css = { "prettierd" },
		scss = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescript = { "prettierd" },
		typescriptreact = { "prettierd" },
		c = { "clang-format" },
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
			width = 0.92,
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
})

vim.opt.ruler = false
vim.opt.signcolumn = "no"
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.guicursor = "n-v-c-i:block"
vim.opt.cursorline = true
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
vim.o.termguicolors = true
vim.o.background = "light"

vim.api.nvim_create_autocmd(
	{ "FileChangedShellPost" },
	{ command = 'echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None', pattern = { "*" } }
)

vim.cmd("autocmd BufRead,BufNewFile Jenkinsfile* set filetype=groovy")
vim.cmd("autocmd BufEnter set filetype=groovy")
vim.cmd("autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>")
vim.cmd("nnoremap <C-o> <C-i>")
vim.cmd("nnoremap <C-i> <C-o>")

vim.cmd(
	"autocmd BufRead,BufNewFile */templates/*.{yaml,yml},*/templates/*.tpl,*.gotmpl,helmfile*.{yaml,yml} set ft=helm"
)

vim.keymap.set("n", "<C-s>", telescope_builtin.git_status, {})

vim.keymap.set("n", "<C-p>", function()
	local git_root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]

	if vim.v.shell_error ~= 0 or not git_root or git_root == "" then
		vim.notify("Not a git repo", vim.log.levels.ERROR)
		return
	end

	git_root = vim.fs.normalize(git_root)

	local function normalize(path)
		return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
	end

	local function rel_to_root(path)
		local abs = normalize(path)
		local prefix = git_root .. "/"
		if vim.startswith(abs, prefix) then
			return abs:sub(#prefix + 1)
		end
		return nil
	end

	local function is_real_file(path)
		return vim.fn.filereadable(path) == 1
	end

	local files = vim.fn.systemlist({
		"git",
		"-C",
		git_root,
		"ls-files",
		"--cached",
		"--others",
		"--exclude-standard",
	})

	local file_set = {}
	local deduped = {}

	for _, f in ipairs(files) do
		local abs = normalize(git_root .. "/" .. f)
		if is_real_file(abs) and not file_set[f] then
			file_set[f] = true
			deduped[#deduped + 1] = f
		end
	end

	files = deduped

	for _, f in ipairs(vim.v.oldfiles) do
		local abs = normalize(f)
		local rel = rel_to_root(abs)
		if rel and is_real_file(abs) and not file_set[rel] then
			file_set[rel] = true
			files[#files + 1] = rel
		end
	end

	local rank = {}
	local n = 0

	local function add_rank(rel)
		if rel and file_set[rel] and not rank[rel] then
			n = n + 1
			rank[rel] = n
		end
	end

	local bufs = vim.fn.getbufinfo({ buflisted = 1 })
	table.sort(bufs, function(a, b)
		return (a.lastused or 0) > (b.lastused or 0)
	end)

	for _, b in ipairs(bufs) do
		if b.name and b.name ~= "" then
			local abs = normalize(b.name)
			local rel = rel_to_root(abs)
			if rel and is_real_file(abs) then
				add_rank(rel)
			end
		end
	end

	for _, f in ipairs(vim.v.oldfiles) do
		local abs = normalize(f)
		local rel = rel_to_root(abs)
		if rel and is_real_file(abs) then
			add_rank(rel)
		end
	end

	table.sort(files, function(a, b)
		local ra, rb = rank[a], rank[b]
		if ra and rb then
			return ra < rb
		end
		if ra then
			return true
		end
		if rb then
			return false
		end
		return a < b
	end)

	local conf = require("telescope.config").values

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Files",
			cwd = git_root,
			finder = require("telescope.finders").new_table({
				results = files,
				entry_maker = require("telescope.make_entry").gen_from_file({ cwd = git_root }),
			}),
			sorter = conf.file_sorter({}),
			previewer = conf.file_previewer({ cwd = git_root }),
		})
		:find()
end)

vim.keymap.set("n", "<C-f>", telescope_builtin.live_grep, {})
vim.keymap.set("n", "<C-y>", telescope_builtin.resume, {})
vim.keymap.set("n", "<C-b>", telescope_builtin.diagnostics, {})
vim.keymap.set("n", "<leader>w", vim.cmd.w, {})
vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "-", "<CMD>Oil<CR>", {})

vim.keymap.set("n", "<leader>Y", function()
	vim.cmd(':let @+ = expand("%:p")')
end, {})

vim.keymap.set("n", "<leader>b", function()
	local current_line = vim.fn.line(".")
	local file = vim.fn.expand("%:p")
	local result = vim.fn.systemlist({ "git", "blame", file })
	if vim.v.shell_error ~= 0 then
		vim.notify("git blame failed", vim.log.levels.ERROR)
		return
	end
	vim.cmd("vnew")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, result)
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.api.nvim_buf_set_name(0, "git blame")
	vim.api.nvim_win_set_cursor(0, { current_line, 0 })
	vim.cmd("normal! zz")
end, {})

vim.keymap.set("x", "gd", function()
	local mode = vim.fn.mode()
	local t = mode == "V" and "V" or "v"
	local text = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = t }), " ")
	telescope_builtin.live_grep({ default_text = text })
end, {})

vim.lsp.enable("jsonls")
vim.lsp.enable("cssls")
vim.lsp.enable("pyright")

vim.lsp.config.lua_ls = {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "love" },
			},
		},
	},
}
vim.lsp.enable("lua_ls")

vim.lsp.config("clangd", {
	cmd = { "clangd", "--background-index", "--clang-tidy" },
	filetypes = { "c", "h", "cpp", "hpp" },
})

vim.lsp.enable("clangd")
vim.lsp.enable("tsgo")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),

	callback = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
		local opts = { buffer = ev.buf }

		vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, opts)
		vim.keymap.set("n", "gt", telescope_builtin.lsp_type_definitions, opts)
		vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, opts)
		vim.keymap.set({ "n", "v" }, "K", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

		for _, k in ipairs({ "grr", "grn", "gri", "grt", "grx" }) do
			pcall(vim.keymap.del, "n", k)
		end

		pcall(vim.keymap.del, { "n", "x" }, "gra")

		vim.keymap.set("n", "gr", function()
			telescope_builtin.lsp_references({ trim_text = true, show_line = false, buffer = ev.buf })
		end, opts)

		vim.keymap.set({ "n", "v" }, "L", function()
			vim.diagnostic.open_float(0, { scope = "line" })
		end, opts)

		vim.keymap.set("n", "<C-m>", function()
			vim.diagnostic.goto_next({ float = false, severity = "error" })
		end, opts)

		vim.keymap.set("n", "<leader>w", function()
			vim.cmd.wall({ bang = true })
		end, opts)
	end,
})

require("gruvbox").setup({
	overrides = {
		Visual = { bg = "#ebdbb2", reverse = false },
	},
})

vim.o.background = "light"
vim.cmd.colorscheme("gruvbox")
