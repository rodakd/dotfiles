vim.api.nvim_create_user_command("Hello", function()
	require("hello").hello()
end, {})
