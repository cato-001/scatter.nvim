local M = {}

M.edit_file = function(path)
	vim.cmd('vertical edit ' .. path)

	local window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(window, vim.o.columns)
	vim.api.nvim_win_set_height(window, vim.o.lines)
end

M.reload_file = function(path)
	if path == nil then
		vim.cmd.edit('%')
	end
	vim.cmd.edit(path)
end

return M
