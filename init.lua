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
	"nordtheme/vim",
	"nvim-lua/plenary.nvim",
	"nvim-telescope/telescope.nvim",
	{
		"neovim/nvim-lspconfig",
		commit = "43ed3797b266e1ee8d222e491379ad471c9d3146",
	},
	{ "dstein64/nvim-scrollview", opts = {} },
	{ "nvim-tree/nvim-web-devicons", opts = {} },
	{
		"axkirillov/unified.nvim",
		opts = {
			-- Dedicated muted groups instead of the bright Diff{Add,Delete,Change}
			highlights = {
				add = "UnifiedMutedAdd",
				delete = "UnifiedMutedDelete",
				change = "UnifiedMutedChange",
			},
		},
		config = function(_, opts)
			require("unified").setup(opts)

			-- Muted Nord-tinted hunk colors: subtle backgrounds, soft foregrounds.
			local function muted_hunk_colors()
				vim.api.nvim_set_hl(0, "UnifiedMutedAdd", { bg = "#2F4034", fg = "#A3BE8C" })
				vim.api.nvim_set_hl(0, "UnifiedMutedDelete", { bg = "#3F343A", fg = "#BF616A" })
				vim.api.nvim_set_hl(0, "UnifiedMutedChange", { bg = "#3E4A5E", fg = "#81A1C1" })
				-- Nord's DiffChange is yellow (nord13 #EBCB8B), which shows up in
				-- unified.nvim's file tree (modified files) and diffs. Replace it
				-- with a muted blue.
				vim.api.nvim_set_hl(0, "DiffChange", { bg = "#3E4A5E", fg = "#81A1C1" })
			end
			muted_hunk_colors()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("UnifiedMutedColors", { clear = true }),
				callback = muted_hunk_colors,
			})

			-- Jump focus to the diff buffer when a file is selected in the tree
			-- (the plugin keeps focus in the tree by default). The tree's keymaps
			-- look these up via require at keypress time, so wrapping works.
			local actions = require("unified.file_tree.actions")
			local function focus_main_window()
				local win = require("unified.state").get_main_window()
				if win and vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_set_current_win(win)
				end
			end
			for _, name in ipairs({ "toggle_node", "move_cursor_and_open_file" }) do
				local orig = actions[name]
				if orig then
					actions[name] = function(...)
						orig(...)
						focus_main_window()
					end
				end
			end

			-- The plugin hardcodes a 300ms auto-refresh debounce with no config
			-- option; re-register its autocmds with a faster one.
			local DEBOUNCE_MS = 50
			local auto_refresh = require("unified.auto_refresh")
			local orig_ar_setup = auto_refresh.setup
			auto_refresh.setup = function(buffer)
				orig_ar_setup(buffer)
				pcall(vim.api.nvim_clear_autocmds, { group = "UnifiedDiffAutoRefresh", buffer = buffer })
				local state = require("unified.state")
				local diff = require("unified.diff")
				local async = require("unified.utils.async")
				local debounced = async.debounce(function()
					if not state.is_active() then
						return
					end
					local ok, commit = pcall(state.get_commit_base)
					if not ok then
						return
					end
					async.run(function()
						require("unified.git").show_git_diff_against_commit(commit, buffer)
					end)
				end, DEBOUNCE_MS)
				vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "FileChangedShell" }, {
					group = vim.api.nvim_create_augroup("UnifiedDiffAutoRefresh", { clear = false }),
					buffer = buffer,
					callback = function()
						if diff.is_diff_displayed(buffer) then
							debounced()
						end
					end,
				})
			end

			-- Show added/deleted lines in the scrollview column while a
			-- unified diff is active.
			local scrollview = require("scrollview")
			local add_group = "unified_add"
			local del_group = "unified_del"
			scrollview.register_sign_group(add_group)
			scrollview.register_sign_group(del_group)

			local add_reg = scrollview.register_sign_spec({ group = add_group, highlight = "UnifiedMutedAdd" })
			local del_reg = scrollview.register_sign_spec({ group = del_group, highlight = "UnifiedMutedDelete" })
			scrollview.set_sign_group_state(add_group, true)
			scrollview.set_sign_group_state(del_group, true)

			local cache = {}

			local function update_diff_signs(bufnr)
				local fname = vim.api.nvim_buf_get_name(bufnr)
				if fname == "" then
					return
				end
				local state = require("unified.state")
				local ok, base = pcall(state.get_commit_base)
				local key = tostring(bufnr)
					.. ":"
					.. tostring(ok and base or "inactive")
					.. ":"
					.. tostring(vim.b[bufnr].changedtick or 0)
				if cache[key] then
					return
				end
				cache = { [key] = true }

				local adds, dels = {}, {}
				if ok and state.is_active() then
					local out = vim.fn.systemlist({ "git", "diff", base, "--", fname })
					if vim.v.shell_error == 0 then
						local line = 0
						for _, l in ipairs(out) do
							-- Skip "+++ b/..." and "--- a/..." file headers
							if l:sub(1, 3) == "+++" or l:sub(1, 3) == "---" then
								goto continue
							end
							local c = l:sub(1, 1)
							if c == "@" then
								local start = tonumber(l:match("%+(%d+)"))
								if start then
									line = start - 1
								end
							elseif c == "+" then
								line = line + 1
								table.insert(adds, line)
							elseif c == "-" then
								-- Deleted lines have no position in the new
								-- file; anchor them to the nearest line.
								table.insert(dels, math.max(1, line))
							elseif c == " " then
								line = line + 1
							end
							::continue::
						end
					end
				end
				vim.b[bufnr][add_reg.name] = adds
				vim.b[bufnr][del_reg.name] = dels
			end

			local function refresh_signs()
				if scrollview.is_sign_group_active(add_group) then
					vim.cmd("ScrollViewRefresh")
				end
			end

			scrollview.set_sign_group_callback(add_group, function()
				for _, winid in ipairs(scrollview.get_sign_eligible_windows()) do
					update_diff_signs(vim.api.nvim_win_get_buf(winid))
				end
			end)
			scrollview.set_sign_group_callback(del_group, function()
				for _, winid in ipairs(scrollview.get_sign_eligible_windows()) do
					update_diff_signs(vim.api.nvim_win_get_buf(winid))
				end
			end)

			local group = vim.api.nvim_create_augroup("UnifiedScrollViewSigns", { clear = true })
			vim.api.nvim_create_autocmd("User", {
				group = group,
				pattern = "UnifiedBaseCommitUpdated",
				callback = refresh_signs,
			})
			vim.api.nvim_create_autocmd({ "BufWinEnter", "BufWritePost", "TextChanged" }, {
				group = group,
				callback = function()
					if require("unified.state").is_active() then
						refresh_signs()
					end
				end,
			})
		end,
	},
	{
		"stevearc/oil.nvim",
		opts = {
			keymaps = {
				["<C-p>"] = false,
				["<C-s>"] = false,
			},

			view_options = {
				show_hidden = true,
			},

			skip_confirm_for_simple_edits = true,
		},
	},
	{
		"nvim-pack/nvim-spectre",
		opts = {
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
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			notify_on_error = false,

			format_on_save = {
				lsp_format = "fallback",
			},

			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "oxfmt", "prettierd" },
				json = { "prettierd" },
				css = { "oxfmt", "prettierd" },
				scss = { "oxfmt", "prettierd" },
				javascriptreact = { "oxfmt", "prettierd" },
				typescript = { "oxfmt", "prettierd" },
				typescriptreact = { "oxfmt", "prettierd" },
				html = { "oxfmt", "prettierd" },
				c = { "clang-format" },
			},
		},
	},
	{
		"saghen/blink.cmp",
		version = "1.*",

		opts = {
			keymap = { preset = "enter", ["<C-e>"] = { "show", "show_documentation", "hide_documentation" } },
			completion = {
				menu = {
					auto_show = false,
				},
				list = {
					selection = {
						preselect = false,
					},
				},
			},
		},

		opts_extend = { "sources.default" },
	},
})

local telescope = require("telescope")
local telescope_actions = require("telescope.actions")
local telescope_builtin = require("telescope.builtin")

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

vim.keymap.set("n", "<leader>d", function()
	local state = require("unified.state")

	if state.is_active() then
		require("unified.command").reset()
		vim.cmd("ScrollViewRefresh")
		return
	end

	local branch = vim.trim(vim.fn.input("Diff against branch: "))

	if branch ~= "" then
		local merge_base = vim.trim(vim.fn.system({ "git", "merge-base", branch, "HEAD" }))
		if vim.v.shell_error ~= 0 or merge_base == "" then
			vim.notify("merge-base failed for " .. branch, vim.log.levels.ERROR)
			return
		end
		require("unified.command").run(merge_base)
	end
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

local function grep_current_file()
	local file = vim.api.nvim_buf_get_name(0)

	if file == "" then
		return
	end

	require("telescope.builtin").grep_string({
		search = vim.fn.expand("<cword>"),
		search_dirs = { file },
		additional_args = function()
			return {
				"--word-regexp",
				"--fixed-strings",
			}
		end,
	})
end

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

		vim.keymap.set("n", "gR", grep_current_file, opts)

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

vim.cmd([[colorscheme nord]])
