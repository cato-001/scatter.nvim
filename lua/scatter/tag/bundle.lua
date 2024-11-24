--- @class Bundle
--- @field tags string[]
--- @field persons string[]
--- @field actions string[]
local Bundle = {}
Bundle.__index = Bundle

--- @return Bundle
function Bundle:empty()
	return setmetatable({
		tags = {},
		actions = {},
		persons = {}
	}, self)
end

--- @param content string
--- @return Bundle
function Bundle:from_content(content)
	local bundle = self:empty()
	bundle:add_content(content)
	return bundle
end

--- @param content string
function Bundle:update_content(content)
	self:_clear()
	self:add_content(content)
end

function Bundle:_clear()
	local util = require('scatter.util')
	util.table_clear(self.tags)
	util.table_clear(self.actions)
	util.table_clear(self.persons)
end

--- @param content string
function Bundle:add_content(content)
	if content == nil then
		return
	end

	local function parse_pattern_into(buffer, pattern)
		for item in string.gmatch(content, pattern) do
			table.insert(buffer, item)
		end
	end

	local pattern = require('scatter.tag.pattern')

	parse_pattern_into(self.tags, pattern.NORMAL)
	parse_pattern_into(self.actions, pattern.ACTION)
	parse_pattern_into(self.persons, pattern.PERSON)
end

--- @return string[]
function Bundle:get_all()
	local all = {}
	vim.list_extend(all, self.tags)
	vim.list_extend(all, self.persons)
	vim.list_extend(all, self.actions)
	return all
end

--- @return string[]
function Bundle:get_lines()
	local lines = {}
	if #self.tags ~= 0 then
		local tags = table.concat(self.tags, ' ')
		table.insert(lines, tags)
	end
	if #self.persons ~= 0 then
		local persons = table.concat(self.persons, ' ')
		table.insert(lines, persons)
	end
	if #self.actions ~= 0 then
		local actions = table.concat(self.actions, ' ')
		table.insert(lines, actions)
	end
	return lines
end

--- @return string
function Bundle:to_string()
	return table.concat(self:get_lines(), '\n')
end

return Bundle
