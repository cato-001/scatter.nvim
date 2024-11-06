local util = require('scatter.util')

local M = {
	TAG_PATTERN = '#[%a%däÄöÖüÜß][%a%däÄöÖüÜß%_%-]+[%a%däÄöÖüÜß]',
	ACTION_PATTERN = '~[a-zA-Z0-9][a-zA-Z0-9%-%_]+[a-zA-Z0-9]',
	PERSON_PATTERN = '@[a-zA-ZäÄöÖüÜß][a-zA-Z-äÄöÖüÜß_%-]+[a-zA-ZäÄöÖüÜß]',
}

M.Bundle = {}
M.Bundle.__index = M.Bundle

function M.Bundle:empty()
	return setmetatable({
		tags = {},
		actions = {},
		persons = {}
	}, self)
end

function M.Bundle:from_content(content)
	local bundle = self:empty()
	bundle:add_content(content)
	return bundle
end

function M.Bundle:update_content(content)
	self:_clear()
	self:add_content(content)
end

function M.Bundle:_clear()
	util.table_clear(self.tags)
	util.table_clear(self.actions)
	util.table_clear(self.persons)
end

function M.Bundle:add_content(content)
	local function parse_pattern_into(buffer, pattern)
		for item in string.gmatch(content, pattern) do
			table.insert(buffer, item)
		end
	end

	parse_pattern_into(self.tags, M.TAG_PATTERN)
	parse_pattern_into(self.actions, M.ACTION_PATTERN)
	parse_pattern_into(self.persons, M.PERSON_PATTERN)
end

function M.Bundle:to_string()
	local lines = {}
	if #self.tags ~= 0 then
		local tags = table.concat(self.tags, ' ')
		table.insert(lines, tags)
	end
	if #self.persons ~= 0 then
		local persons = table.concat(self.persons, ' ')
		table.insert(lines, persons)
	end
	return table.concat(lines, '\n')
end

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
	local NotesIterator = require('scatter.notes.iterator')
	local tags = {}
	for note in NotesIterator:new() do
		vim.list_extend(tags, note.bundle.tags)
	end
	for index = #tags, 1, -1 do
		if is_timestamp(tags[index]) then
			table.remove(tags, index)
		end
	end
	util.table_sort_without_duplicates(tags)

	return tags
end

M.replace = function(text, prev, new)
	return string.gsub(text, M.TAG_PATTERN, function(tag)
		if tag == prev then
			return new
		else
			return tag
		end
	end)
end

M.remove_all = function(text)
	local function remove_tag_char(tag)
		return string.lower(string.sub(tag, 2))
	end
	local content = text
	content = string.gsub(content, M.TAG_PATTERN, '')
	content = string.gsub(content, M.ACTION_PATTERN, '')
	content = string.gsub(content, M.PERSON_PATTERN, '')
	if string.match(content, '^%s*$') then
		return ''
	end

	text = string.gsub(text, M.TAG_PATTERN, remove_tag_char)
	text = string.gsub(text, M.ACTION_PATTERN, remove_tag_char)
	return string.gsub(text, M.PERSON_PATTERN, remove_tag_char)
end

return M
