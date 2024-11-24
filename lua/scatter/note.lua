local config = require('scatter.config')

--- @class Note
--- @field source Source
--- @field todos Todo
local Note = {}
Note.__index = Note

--- @param date string?
--- @return Note
function Note:new(date)
	local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	local note_date = date or os.date('%Y-%m-%d')

	local filepath
	while true do
		local chars = {}
		for _ = 1, 20, 1 do
			local position = math.random(#charset)
			table.insert(chars, string.sub(charset, position, position))
		end
		local randstr = table.concat(chars, '')
		local filename = note_date .. '_' .. randstr .. '.md'
		filepath = vim.fs.joinpath(config.notes_path, filename)
		if vim.loop.fs_stat(filepath) == nil then
			break
		end
	end

	local Source = require('scatter.source')
	local source = Source:from_file(filepath)
	source:create_if_missing()

	return setmetatable({
		source = source,
		todos = {},
	}, self)
end

--- @param source Source
--- @return Note?
function Note:from(source)
	if not source:path_starts_with(config.notes_path) then
		return nil
	end

	return setmetatable({
		source = source,
		todos = {}
	}, self)
end

--- @param needles string[]?
--- @return boolean
function Note:match_all(needles)
	if needles == nil then
		return true
	end
	for _, needle in ipairs(needles) do
		if not self:match(needle) then
			return false
		end
	end
	return true
end

--- @param needles string[]
--- @return boolean
function Note:match_any(needles)
	for _, needle in ipairs(needles) do
		if self:match(needle) then
			return true
		end
	end
	return false
end

--- @param needle string
--- @return boolean
function Note:match(needle)
	local bundle = self.source:get_bundle()
	for _, tag in ipairs(bundle.tags) do
		if string.find(tag, needle, nil, true) then
			return true
		end
	end
	return false
end

--- @param mapping table<string, string>
function Note:replace_tags(mapping)
	if #mapping == 0 then
		return
	end
	local tag = require('scatter.tag')
	self.source:modify(function(lines)
		for index, line in ipairs(lines) do
			lines[index] = tag.replace(line, mapping)
		end
		return lines
	end)
end

--- @param name string
--- @return boolean
function Note:has_tag(name)
	local bundle = self.source:get_bundle()
	if bundle == nil then
		return false
	end
	return vim.list_contains(bundle.tags, name)
end

--- @param pattern string | number
--- @return string[]
function Note:find_tags(pattern)
	local bundle = self.source:get_bundle()
	if bundle == nil then
		return {}
	end
	local tags = {}
	for _, tag in ipairs(bundle) do
		if string.match(tag, pattern) then
			table.insert(tags, tag)
		end
	end
	return tags
end

--- @param action string
--- @return boolean
function Note:has_action(action)
	local bundle = self.source:get_bundle()
	if bundle == nil then
		return false
	end
	return vim.list_contains(bundle.actions, action)
end

--- @return (fun(): CodeBlock?) | nil
function Note:iter_code_rev()
	local lines = self.source:get_lines()
	if lines == nil then
		return
	end

	local CodeBlock = require('scatter.note.code')
	local index = #lines
	return function()
		local end_line = nil
		while index > 0 do
			local line = lines[index]
			if string.find(line, '^```') then
				if end_line == nil then
					end_line = index
				else
					local start_line = index
					index = index - 1
					return CodeBlock:new(self, start_line, end_line)
				end
			end
			index = index - 1
		end
		return nil
	end
end

return Note
