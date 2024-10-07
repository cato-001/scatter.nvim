local config = require('scatter.config')

local M = {}

M.table_clear = function(values)
	local count = #values
	for index = 1, count do
		values[index] = nil
	end
end

M.table_sort_without_duplicates = function(values)
	table.sort(values)
	local prev = nil
	for index = #values, 1, -1 do
		local item = values[index]
		if item == prev then
			table.remove(values, index)
		end
		prev = item
	end
end

M.is_scatter_file = function(path)
	if string.find(path, config.path) then
		return true
	end
	for _, runtimepath in ipairs(vim.api.nvim_get_runtime_file(path, true)) do
		print('runtime', runtimepath)
		if string.find(runtimepath, config.path) then
			return true
		end
	end
	return false
end

return M
