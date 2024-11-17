local Source = {}
Source.__index = Source

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
	error('unknown source type', source_type)
end

function Source:from_buffer(buffer)
	return setmetatable({
		source_type = 'buffer',
		buffer = buffer,
	}, self)
end

function Source:from_file(path)
	return setmetatable({
		source_type = 'file',
		path = path,
	}, self)
end

function Source:from_date(date)
	return setmetatable({
		source_type = 'date',
		date = date,
	})
end

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
	error('unknown source type', self.source_type)
end

function Source:get_date()
	if self.source_type == 'date' then
		return self.date
	end
	local util = require('scatter.util')
	local path = self:get_path()
	if not util.is_carlender_file(path) then
		return nil
	end
	local date_year = path:match('year%-(%d+)')
	local date_month = path:match('month%-(%d+)')
	local date_day = path:match('day%-(%d+)')
	if date_year == nil or date_month == nil or date_day == nil then
		return nil
	end
	return table.concat({ date_year, date_month, date_day }, '-')
end

function Source:get_lines()
	if self.source_type == 'buffer' then
		return vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false)
	end
	local lines = {}
	for line in io.lines(self:get_path()) do
		table.insert(lines, line)
	end
	return lines
end

function Source:is_note()
	local util = require('scatter.util')
	local path = self:get_path()
	return util.is_note_file(path)
end

function Source:is_carlender()
	local util = require('scatter.util')
	local path = self:get_path()
	return util.is_carlender_file(path)
end

function Source:get_object()
	if self:is_note() then
		local Note = require('scatter.note')
		return Note:from_source(self)
	end
	if self:is_carlender() then
		local Carlender = require('scatter.carlender')
		return Carlender:from_source(self)
	end
	return nil
end

return Source
