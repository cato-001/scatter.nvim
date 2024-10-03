local util = require('scatter.util')
local config = require('scatter.config')
local edit = require('scatter.edit')
local generate_name = require('scatter.notes.name').generate

local TAG_PATTERN = '#[a-zA-Z0-9][a-zA-Z0-9-_]+[a-zA-Z0-9]'
local ACTION_PATTERN = '~[a-zA-Z0-9][a-zA-Z0-9-_]+[a-zA-Z0-9]'
local PERSON_PATTERN = '@[a-zA-Z][a-zA-Z-_]+[a-zA-Z]'

local Note = {}

function Note:load(name, path)
	local note = {
		name = name,
		path = path or vim.fs.joinpath(config.notes_path, name),
		tags = {},
		actions = {},
	}

	setmetatable(note, self)
	self.__index = self

	local file = io.open(note.path)
	if not file then
		return nil
	end
	note.content = file:read('*a')
	file:close()

	note:_update_tags()
	note:_update_actions()

	return note
end

function Note:from_content(content, date)
	local name, path = generate_name(date)
	local note = {
		name = name,
		path = path,
		tags = {},
		actions = {},
		content = content,
	}

	setmetatable(note, self)
	self.__index = self

	note:_update_tags()
	note:_update_actions()

	return note
end

function Note:save()
	local file = io.open(self.path, 'w')
	if not file then
		error('could not save note: ' .. self.path)
	end
	file:write(self.content)
	file:close()
end

function Note:delete()
	os.remove(self.path)
end

function Note:edit()
	self:save()
	edit.edit_file(self.path)
end

function Note:_update_tags()
	util.table_clear(self.tags)
	for tag in string.gmatch(self.content, TAG_PATTERN) do
		tag = string.lower(tag)
		table.insert(self.tags, tag)
	end
	util.table_sort_without_duplicates(self.tags)
end

function Note:_update_actions()
	util.table_clear(self.actions)
	for action in string.gmatch(self.content, ACTION_PATTERN) do
		table.insert(self.actions, action)
	end
	util.table_sort_without_duplicates(self.actions)
end

function Note:get_date()
	local date = string.match(self.name, '^%d+%-%d+%-%d+')
	return date
end

function Note:match_all(needles)
	local result = 0
	for _, needle in ipairs(needles) do
		if self:match(needle) then
			result = result + 1
		end
	end
	return result == #needles, result
end

function Note:match_any(needles)
	for _, needle in ipairs(needles) do
		if self:match(needle) then
			return true
		end
	end
	return false
end

function Note:match(needle)
	for _, tag in ipairs(self.tags) do
		if string.find(tag, needle) then
			return true
		end
	end
	return false
end

function Note:replace_tag(prev, new)
	self.content = string.gsub(self.content, TAG_PATTERN, function(tag)
		if tag == prev then
			return new
		else
			return tag
		end
	end)
	self:_update_tags()
end

function Note:join_tags(sep)
	return table.concat(self.tags, sep)
end

function Note:has_tag(tag)
	return vim.list_contains(self.tags, tag)
end

function Note:find_tags(pattern)
	local tags = {}
	for _, tag in ipairs(self.tags) do
		if string.match(tag, pattern) then
			table.insert(tags, tag)
		end
	end
	return tags
end

function Note:has_action(action)
	return vim.list_contains(self.actions, action)
end

function Note:split()
	if not self:has_action('~split') then
		return false, { self }
	end
	local date = self:get_date()
	local notes = {}
	for content in vim.gsplit(self.content, '~split') do
		local note = Note:from_content(content, date)
		table.insert(notes, note)
	end
	return true, notes
end

return Note
