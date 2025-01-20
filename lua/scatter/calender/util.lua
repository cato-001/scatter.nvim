local config = require('scatter.config')

local M = {}

M.is_calender_file = function(path)
	local calender_base = vim.fs.normalize(vim.fn.fnamemodify(config.calender_path, ':p'))
	local file_base = vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))

	return file_base:sub(1, #calender_base) == calender_base
end

return M
