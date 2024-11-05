local config = require('scatter.config')

local M = {}

M.is_carlender_file = function(path)
	local carlender_base = vim.fs.normalize(vim.fn.fnamemodify(config.carlender_path, ':p'))
	local file_base = vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))

	return file_base:sub(1, #carlender_base) == carlender_base
end

return M
