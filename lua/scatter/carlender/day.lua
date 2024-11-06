local edit = require('scatter.edit')
local config = require('scatter.config')
local util = require('scatter.util')

local Day = {}

function Day:new(date)
	local date_year, date_month, date_day = date:match('(%d+)%-(%d+)%-(%d+)')
	local path = vim.fs.joinpath(
		config.carlender_path, 'year-' .. date_year, 'month-' .. date_month, 'day-' .. date_day .. '.md')

	local dirname = vim.fs.dirname(path)
	vim.loop.fs_mkdir(dirname, tonumber("644", 8))

	local day = setmetatable({
		date = date,
		year = tonumber(date_year),
		month = tonumber(date_month),
		day = tonumber(date_day),
		path = path,
		content = "",
		appointments = {},
	}, self)
	self.__index = self

	return day
end

function Day:load(date)
	local day = Day:new(date)

	local file = io.open(self.path, 'r')
	if file == nil then
		error('could not open carlender: ' .. self.path)
	end
	day.content = file:read('*a')
	file:close()

	return day
end

function Day:today()
	local date = os.date('%Y-%m-%d')
	return Day:new(date)
end

function Day:save()
end

function Day:edit()
	self:save()
	edit.edit_file(self.path)
end

function Day:file_exists()
	local stat = vim.loop.fs_stat(self.path)
	return stat ~= nil
end

function Day:_parse_appointments()
	util.table_clear(self.appointments)
end

function Day:_reorder_appointments()
	table.sort(self.appointments, function(start, other)
		return start < other
	end)
end

return Day
