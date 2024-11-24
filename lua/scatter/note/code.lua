--- @class CodeBlock
--- @field note Note
--- @field start_line integer
--- @field end_line integer
--- @field lines_cache string[]?
--- @field lines_cache_version integer
local CodeBlock = {}
CodeBlock.__index = CodeBlock

--- @param note Note
--- @param start_line integer
--- @param end_line integer
--- @return CodeBlock?
function CodeBlock:new(note, start_line, end_line)
	if start_line >= end_line then
		return nil
	end
	return setmetatable({
		note = note,
		start_line = start_line,
		end_line = end_line,
		lines_cache_version = 0,
	}, self)
end

function CodeBlock:get_lines()
	if self.lines_cache ~= nil and self.lines_cache_version == self.note.source.lines_cache_version then
		return self.lines_cache
	end
	local lines = self.note.source:get_lines()
	if lines == nil then
		return
	end
	self.lines_cache_version = self.note.source.lines_cache_version
	self.lines_cache = vim.list_slice(lines, self.start_line, self.end_line)
	return self.lines_cache
end

--- @return string[]?
function CodeBlock:get_actions()
	local lines = self:get_lines()
	if lines == nil then
		return nil
	end
	local pattern = require('scatter.tag.pattern')
	local first = lines[1]
	local actions = {}
	for item in string.gmatch(first, pattern.ACTION) do
		table.insert(actions, item)
	end
	return actions
end

--- @return string?
function CodeBlock:get_language()
	local lines = self:get_lines()
	if lines == nil then
		return
	end
	local language = string.match(lines[1], '^```%s*([^%s]+)')
	return language
end

--- @return string?
function CodeBlock:get_content()
	local lines = self:get_lines()
	if lines == nil then
		return
	end
	return table.concat(vim.list_slice(lines, 2, #lines - 1), '\n')
end

return CodeBlock
