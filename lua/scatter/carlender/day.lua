local config = require('scatter.config')

local Day = {}

function Day:new(date)
	local day = {}
	setmetatable(day, self)
	self.__index = self

	day.date = date

	day.year, day.month, day.day = string.gmatch(date, '(%d+)%-(%d+)%-(%d+)')
	day.year = tonumber(day.year)
	day.month = tonumber(day.month)
	day.day = tonumber(day.day)

	day.path = vim.fs.joinpath(
		config.carlender_path, 'year-' .. day.year, 'month-' .. day.month, 'day-' .. day.day .. '.md')

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
	return stat != nil
end

return Day
