local M = {}

function M.hello()
	vim.notify("Hello from hello.nvim!", vim.log.levels.INFO)
end

return M
