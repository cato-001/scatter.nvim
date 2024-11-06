local edit = require('scatter.edit')
local config = require('scatter.config')
local util = require('scatter.util')
local Appointment = require('scatter.carlender.appointment')

local Day = {}
Day.__index = Day

function Day:new(date)
	local date_year, date_month, date_day = date:match('(%d+)%-(%d+)%-(%d+)')
	local path = vim.fs.joinpath(
		config.carlender_path, 'year-' .. date_year, 'month-' .. date_month, 'day-' .. date_day .. '.md')

	local dirname = vim.fs.dirname(path)
	vim.loop.fs_mkdir(dirname, tonumber("644", 8))

	return setmetatable({
		date = date,
		year = tonumber(date_year),
		month = tonumber(date_month),
		day = tonumber(date_day),
		path = path,
		content = "",
		appointments = {},
	}, self)
end

function Day:load(date)
	local day = Day:new(date)

	local file = io.open(day.path, 'r')
	if file == nil then
		error('could not open carlender: ' .. day.path)
	end
	day.content = file:read('*a')
	file:close()

	return day
end

function Day:today()
	local date = os.date('%Y-%m-%d')
	return Day:load(date)
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

	local appointment = nil
	for line in vim.gsplit(self.content, '\n', { plain = true }) do
		line = string.gsub(line, '^%s+', '')
		line = string.gsub(line, '%s+$', '')
		if line == '' then
			if appointment ~= nil then
				table.insert(self.appointments, appointment)
				appointment = nil
			end
		elseif appointment == nil then
			appointment = Appointment:from_times(line)
		else
			appointment:add_comment(line)
		end
	end

	for _, item in ipairs(self.appointments) do
		print(item:to_string_pretty())
	end
end

function Day:_reorder_appointments()
	table.sort(self.appointments, function(start, other)
		return start < other
	end)
end

return Day
