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
	path = vim.fn.fnamemodify(path, ':p')
	return M.string_starts_with(path, config.path)
end

M.is_note_file = function(path)
	path = vim.fn.fnamemodify(path, ':p')
	return M.string_starts_with(path, config.notes_path)
end

M.is_carlender_file = function(path)
	path = vim.fn.fnamemodify(path, ':p')
	return M.string_starts_with(path, config.carlender_path)
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

M.string_starts_with = function(string, start)
	if string == nil or start == nil then
		return false
	end
	return string.sub(string, 1, #start) == start
end

return M
