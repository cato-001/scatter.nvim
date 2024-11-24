--- @class Paragraph
--- @field source Source
--- @field start_line integer
--- @field end_line integer
--- @field lines_cache string[]?
--- @field lines_cache_version integer
--- @field bundle_cache Bundle?
--- @field bundle_cache_version integer
local Paragraph = {}
Paragraph.__index = Paragraph

--- @param source Source
--- @param start_line integer
--- @param end_line integer
--- @return Paragraph?
function Paragraph:new(source, start_line, end_line)
	if start_line >= end_line then
		return nil
	end
	return setmetatable({
		source = source,
		start_line = start_line,
		end_line = end_line,
		lines_cache_version = 0,
		bundle_cache_version = 0,
	}, self)
end

--- @return string[]?
function Paragraph:get_lines()
	if self.lines_cache ~= nil and self.lines_cache_version == self.source.lines_cache_version then
		return self.lines_cache
	end
	local source_lines = self.source:get_lines()
	if source_lines == nil then
		return nil
	end
	self.lines_cache_version = self.source.lines_cache_version
	if self.end_line - 1 > #source_lines then
		error('the end of the paragraph is out of range: ' .. tostring(self.end_line) .. ' / ' .. tostring(#source_lines))
	end
	self.lines_cache = {}
	for index = self.start_line, self.end_line - 1 do
		self.lines_cache[#self.lines_cache + 1] = source_lines[index]
	end
	return self.lines_cache
end

--- @return Bundle?
function Paragraph:get_bundle()
	if self.bundle_cache ~= nil and self.bundle_cache_version == self.lines_cache_version then
		return self.bundle_cache
	end
	local lines = self:get_lines()
	if lines == nil then
		return nil
	end
	self.bundle_cache_version = self.lines_cache_version
	local Bundle = require('scatter.tag.bundle')
	self.bundle_cache = Bundle:empty()
	for _, line in ipairs(lines) do
		self.bundle_cache:add_content(line)
	end
	return self.bundle_cache
end

--- @param name string
--- @return boolean
function Paragraph:has_action(name)
	local bundle = self:get_bundle()
	if bundle == nil then
		return false
	end
	return vim.list_contains(bundle.actions, name)
end

--- @param callback fun(lines: string[]): string[]
function Paragraph:modify(callback)
	local lines = self:get_lines()
	if lines == nil then
		return
	end
	local new_lines = callback(lines)
	if lines == nil or #lines == 0 or lines == new_lines then
		return
	end
	self.source:_set_lines_in_range(self.start_line - 1, self.end_line - 1, new_lines)
end

return Paragraph
