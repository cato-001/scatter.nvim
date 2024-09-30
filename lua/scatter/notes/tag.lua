local NotesIterator = require('scatter.notes.iterator')
local util = require('scatter.util')

local M = {}

local function is_timestamp(tag)
	if string.find(tag, '^#date%-%d+%-%d+%-%d+$') then
		return true
	end
	if string.find(tag, '^#time%-%d+%-%d+$') then
		return true
	end
	if string.find(tag, '^#year%-%d+$') then
		return true
	end
	return false
end

M.load_all_tags = function()
	local iter = NotesIterator:new()

	local tags = {}
	while true do
		local note = iter:next_note()
		if not note then
			break
		end
		vim.list_extend(tags, note.tags)
	end
	for index = #tags, 1, -1 do
		if is_timestamp(tags[index]) then
			table.remove(tags, index)
		end
	end
	util.table_sort_without_duplicates(tags)

	return tags
end

return M
