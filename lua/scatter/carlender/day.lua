local config = require('scatter.config')
local util = require('scatter.util')

local Day = {}

function Day:new(date)
	local year, month, day = string.gmatch(date, '(%d+)%-(%d+)%-(%d+)')
	local path = vim.fs.joinpath(
		config.carlender_path, 'year-' .. day.year, 'month-' .. day.month, 'day-' .. day.day .. '.md')

	local day = setmetatable({
		date = date,
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
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

function Day:file_exists()
	local stat = vim.loop.fs_stat(self.path)
	return stat ~= nil
end

function Day:_parse_appointments()
	util.table_clear(self.appointments)
end

return Day
