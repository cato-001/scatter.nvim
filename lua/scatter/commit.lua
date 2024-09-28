local config = require('scatter.config')

local M = {}

M.commit_notes = function()
	vim.fn.system({ 'git', 'add', '--all' }, {
		cwd = config.path
	})

	local changes = vim.fn.systemlist({ 'git', 'status', '--short' }, {
		cwd = config.path
	})
	if #changes ~= 0 then
		vim.fn.system({ 'git', 'commit', '-m', '"update notes"' }, {
			cwd = config.path
		})
	end

	vim.fn.system({ 'git', 'pull', '--rebase' }, {
		cwd = config.path
	})
	vim.fn.system({ 'git', 'push' }, {
		cwd = config.path
	})
end

return M
