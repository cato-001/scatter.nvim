local util = require('scatter.util')

local M = {}

--- @param tag string
--- @return boolean
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
	local note_iter = require('scatter.note.iter')
	local tags = {}
	for note in note_iter() do
		local bundle = note.source:get_bundle()
		vim.list_extend(tags, bundle:get_all())
	end
	for index = #tags, 1, -1 do
		if is_timestamp(tags[index]) then
			table.remove(tags, index)
		end
	end
	util.table_sort_without_duplicates(tags)

	return tags
end

--- @param text string
--- @param mapping table<string, string>
--- @return string
M.replace = function(text, mapping)
	return string.gsub(text, M.TAG_PATTERN, function(tag)
		return mapping[tag] or tag
	end)
end

--- @param text string
--- @return string
M.remove_all = function(text)
	local pattern = require('scatter.tag.pattern')

	local function remove_tag_char(tag)
		return string.lower(string.sub(tag, 2))
	end

	local content = text
	content = string.gsub(content, pattern.NORMAL, '')
	content = string.gsub(content, pattern.PERSON, '')
	content = string.gsub(content, pattern.ACTION, '')
	if string.match(content, '^%s*$') then
		return ''
	end

	text = string.gsub(text, pattern.NORMAL, remove_tag_char)
	text = string.gsub(text, pattern.PERSON, remove_tag_char)
	return string.gsub(text, pattern.ACTION, remove_tag_char)
end

return M
