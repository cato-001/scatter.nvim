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
	return string.find(path, config.path)
end

M.concat_lines = function(values)
	for index, line in ipairs(values) do
		if type(line) == "table" then
			line = table.concat(line, ' ')
		end
		values[index] = line
	end
	return table.concat(values, '\n')
end

return M
