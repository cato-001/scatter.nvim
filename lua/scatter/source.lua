--- @class Source
--- @field source_type 'buffer'|'file'|'date'
--- @field buffer integer
--- @field date string
--- @field path string
--- @field bundle Bundle?
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
	return setmetatable({
		source_type = 'buffer',
		buffer = buffer,
	}, self)
end

--- @param path string
--- @return Source
function Source:from_file(path)
	return setmetatable({
		source_type = 'file',
		path = path,
	}, self)
end

--- @param date string
--- @return Source
function Source:from_date(date)
	return setmetatable({
		source_type = 'date',
		date = date,
	}, self)
end

--- @return string | nil
function Source:get_path()
	if self.source_type == 'buffer' then
		return vim.api.nvim_buf_get_name(self.buffer)
	end
	if self.source_type == 'file' then
		return self.path
	end
	if self.source_type == 'date' then
		local date_year, date_month, date_day = self.date:match('(%d+)%-(%d+)%-(%d+)')
		if date_year == nil or date_month == nil or date_day == nil then
			return nil
		end
		local config = require('scatter.config')
		return vim.fs.joinpath(config.carlender_path,
			'year-' .. date_year, 'month-' .. date_month, 'day-' .. date_day .. '.md')
	end
	error('unknown source type: ' + self.source_type)
end

--- @return string?
function Source:get_date()
	if self.source_type == 'date' then
		return self.date
	end
	local path = self:get_path()
	if path == nil then
		return nil
	end

	local filename = vim.fs.basename(path)
	local date = string.match(filename, '^%d+%-%d+%-%d+')
	if date ~= nil then
		return date
	end

	local date_year = self.path:match('year%-(%d+)')
	local date_month = self.path:match('month%-(%d+)')
	local date_day = self.path:match('day%-(%d+)')
	if date_year ~= nil and date_month ~= nil and date_day ~= nil then
		return table.concat({ date_year, date_month, date_day }, '-')
	end

	return nil
end

--- @return string[] | nil
function Source:_get_lines()
	if self.source_type == 'buffer' then
		return vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false)
	end
	local lines = {}
	self:create_if_missing()
	for line in io.lines(self:get_path()) do
		table.insert(lines, line)
	end
	return lines
end

--- @param lines string[]
function Source:_set_lines(lines)
	self.bundle = nil
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

--- @return Bundle
function Source:get_bundle()
	if self.bundle ~= nil then
		return self.bundle
	end
	local Bundle = require('scatter.tag.bundle')
	self.bundle = Bundle:empty()
	local lines = self:_get_lines()
	if lines == nil then
		return self.bundle
	end
	for _, line in ipairs(lines) do
		self.bundle:add_content(line)
	end
	return self.bundle
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
end

--- @param callback fun(lines: string[]): (string[], boolean?)
function Source:modify(callback)
	local lines = self:_get_lines()
	if lines == nil or #lines == 0 then
		return
	end
	local lines, changed = callback(lines)
	if lines ~= nil and (changed == nil or changed) then
		self:_set_lines(lines)
	end
end

function Source:make_parent_directory()
	local path = self:get_path()
	local dirname = vim.fs.dirname(path)
	if dirname == nil then
		return nil
	end
	vim.loop.fs_mkdir(dirname, tonumber("744", 8))
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
