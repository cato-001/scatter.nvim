--- @class Source
--- @field source_type 'buffer'|'file'|'date'
--- @field buffer integer?
--- @field date string?
--- @field path string?
--- @field bundle_cache Bundle?
--- @field bundle_cache_version integer
--- @field lines_cache string[]?
--- @field lines_cache_version integer
local Source = {}
Source.__index = Source

--- @param source_type 'buffer'|'file'|'date'
--- @param value any
--- @return Source
function Source:from(source_type, value)
	if source_type == 'buffer' then
		return self:from_buffer(value)
	end
	if source_type == 'file' then
		return self:from_file(value)
	end
	if source_type == 'date' then
		return self:from_date(value)
	end
	error('unknown source type: ' + source_type)
end

--- @param buffer integer
--- @return Source
function Source:from_buffer(buffer)
	local source = setmetatable({
		source_type = 'buffer',
		buffer = buffer,
		bundle_cache_version = 0,
		lines_cache_version = 1,
	}, self)
	source:_attatch_to_buffer()
	return source
end

--- @param path string
--- @return Source
function Source:from_file(path)
	return setmetatable({
		source_type = 'file',
		path = path,
		bundle_cache_version = 0,
		lines_cache_version = 1
	}, self)
end

--- @param date string
--- @return Source
function Source:from_date(date)
	return setmetatable({
		source_type = 'date',
		date = date,
		bundle_cache_version = 0,
		lines_cache_version = 1
	}, self)
end

function Source:_attatch_to_buffer()
	if self.buffer == nil then
		return
	end
	vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedP', 'TextChangedT' }, {
		buffer = self.buffer,
		callback = function() self:_on_lines_change() end,
	})

	local modules = require('scatter.modules')
	modules.attach_commands(self)
end

function Source:_on_lines_change()
	self.lines_cache = nil
	self.lines_cache_version = self.lines_cache_version + 1
end

--- @return string | nil
function Source:get_path()
	if self.path ~= nil then
		return self.path
	end
	if self.source_type == 'buffer' then
		self.path = vim.api.nvim_buf_get_name(self.buffer)
	elseif self.source_type == 'date' then
		local date_year, date_month, date_day = self.date:match('(%d+)%-(%d+)%-(%d+)')
		if date_year == nil or date_month == nil or date_day == nil then
			return nil
		end
		local config = require('scatter.config')
		self.path = vim.fs.joinpath(config.calender_path,
			'year-' .. date_year, 'month-' .. date_month, 'day-' .. date_day .. '.md')
	end
	return self.path
end

--- @return string?
function Source:get_date()
	if self.date ~= nil then
		return self.date
	end
	local path = self:get_path()
	if path == nil then
		return nil
	end

	local filename = vim.fs.basename(path)
	self.date = string.match(filename, '^%d+%-%d+%-%d+')
	if self.date ~= nil then
		return self.date
	end

	local date_year = self.path:match('year%-(%d+)')
	local date_month = self.path:match('month%-(%d+)')
	local date_day = self.path:match('day%-(%d+)')
	if date_year ~= nil and date_month ~= nil and date_day ~= nil then
		self.date = table.concat({ date_year, date_month, date_day }, '-')
		return self.date
	end

	return nil
end

--- @return string[] | nil
function Source:get_lines()
	if self.lines_cache ~= nil then
		return self.lines_cache
	end
	self.lines_cache_version = self.lines_cache_version + 1
	if self.source_type == 'buffer' then
		self.lines_cache = vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false)
		return self.lines_cache
	end
	self.lines_cache = {}
	self:create_if_missing()
	for line in io.lines(self:get_path()) do
		table.insert(self.lines_cache, line)
	end
	return self.lines_cache
end

--- @param lines string[]
function Source:_set_lines(lines)
	self.lines_cache = lines
	self.lines_cache_version = self.lines_cache_version + 1
	if self.source_type == 'buffer' then
		vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, lines)
		return
	end
	local path = self:get_path()
	if path == nil then
		return
	end
	local file = io.open(path, 'w')
	if file == nil then
		error('could not open file: ' + path)
	end
	file:write(table.concat(lines, '\n'))
	file:close()
end

--- @param start_line integer
--- @param end_line integer
--- @param lines string[]
function Source:_set_lines_in_range(start_line, end_line, lines)
	if self.source_type ~= 'buffer' then
		error('operation not yet supported')
	end
	self.lines_cache_version = self.lines_cache_version + 1
	vim.api.nvim_buf_set_lines(self.buffer, start_line, end_line, false, lines)
end

--- @param lines string[]
function Source:append(lines)
	local whole_lines = self:get_lines()
	if whole_lines == nil then
		return nil
	end
	self:_set_lines_in_range(#whole_lines + 1, #whole_lines + 2, lines)
end

--- @return Bundle?
function Source:get_bundle()
	if self.bundle_cache ~= nil and self.bundle_cache_version == self.lines_cache_version then
		return self.bundle_cache
	end
	local Bundle = require('scatter.tag.bundle')
	self.bundle_cache = Bundle:empty()
	local lines = self:get_lines()
	if lines == nil then
		return nil
	end
	self.bundle_cache_version = self.lines_cache_version
	for _, line in ipairs(lines) do
		self.bundle_cache:add_content(line)
	end
	return self.bundle_cache
end

--- @return string?
function Source:get_name()
	local path = self:get_path()
	return vim.fs.basename(path)
end

function Source:open()
	if self.source_type == 'buffer' then
		vim.api.nvim_set_current_buf(self.buffer)
		return
	end

	local path = self:get_path()
	if path == nil then
		return
	end
	vim.cmd('vertical edit ' .. path)

	local window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(window, vim.o.columns)
	vim.api.nvim_win_set_height(window, vim.o.lines)

	self.source_type = 'buffer'
	self.buffer = vim.api.nvim_get_current_buf()
	self:_attatch_to_buffer()
end

--- @param callback fun(lines: string[]): (string[], boolean?)
function Source:modify(callback)
	local lines = self:get_lines()
	if lines == nil or #lines == 0 then
		return
	end
	local lines, changed = callback(lines)
	if lines ~= nil and (changed == nil or changed) then
		self:_set_lines(lines)
	end
end

--- @return (fun(): Paragraph?) | nil
function Source:iter_paragraphs_rev()
	local lines = self:get_lines()
	if lines == nil then
		return nil
	end

	local Paragraph = require('scatter.source.paragraph')
	local end_line = #lines
	return function()
		local index = end_line - 1
		if index <= 0 then
			return nil
		end
		while index > 0 and not string.find(lines[index] or '', '^%s*$') do
			index = index - 1
		end
		local paragraph = Paragraph:new(self, index + 1, end_line)
		end_line = index
		return paragraph
	end
end

--- @param index integer
--- @return Paragraph?
function Source:get_paragraph_after(index)
	local lines = self:get_lines()
	if lines == nil then
		return nil
	end
	local Paragraph = require('scatter.source.paragraph')
	if index > #lines then
		return nil
	end
	local start_line = index
	while start_line < #lines and string.find(lines[start_line], '^%s*$') do
		start_line = start_line + 1
	end
	local end_line = start_line + 1
	while not string.find(lines[end_line] or '', '^%s*$') do
		end_line = end_line + 1
	end
	return Paragraph:new(self, start_line, end_line)
end

function Source:make_parent_directory()
	local path = self:get_path()
	local dirname = vim.fs.dirname(path)
	if dirname == nil then
		return nil
	end
	vim.loop.fs_mkdir(dirname, tonumber("744", 8))
end

--- @return boolean
function Source:file_exists()
	local path = self:get_path()
	if path == nil then
		return false
	end
	return vim.loop.fs_stat(path) ~= nil
end

--- @param start string
--- @return boolean
function Source:path_starts_with(start)
	local path = self:get_path()
	if path == nil then
		return false
	end
	path = vim.fn.fnamemodify(path, ':p')
	return string.sub(path, 1, #start) == start
end

function Source:create_if_missing()
	self:make_parent_directory()
	local path = self:get_path()
	if path == nil then
		return
	end
	if vim.loop.fs_stat(path) ~= nil then
		return
	end
	local file = io.open(path, 'a')
	if file ~= nil then
		file:write('')
		file:close()
	end
end

function Source:delete()
	local path = self:get_path()

	if self.source_type == 'buffer' then
		vim.api.nvim_buf_delete(self.buffer, {
			force = true,
			unload = true
		})
	end

	if path == nil then
		return
	end
	vim.fs.rm(path, { force = false })
end

return Source
