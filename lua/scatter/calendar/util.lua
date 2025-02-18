local config = require('scatter.config')

local M = {}

M.is_calendar_file = function(path)
	local calendar_base = vim.fs.normalize(vim.fn.fnamemodify(config.calendar_path, ':p'))
	local file_base = vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))

	return file_base:sub(1, #calendar_base) == calendar_base
end

return M
