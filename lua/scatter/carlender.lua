local edit = require('scatter.edit')
local config = require('scatter.config')
local util = require('scatter.util')
local Appointment = require('scatter.carlender.appointment')

local Carlender = {}
Carlender.__index = Carlender

function Carlender:from(opts)
	if type(opts) ~= 'table' then
		return
	end

	local date_year, date_month, date_day
	if opts.date ~= nil then
		date_year, date_month, date_day = opts.date:match('(%d+)%-(%d+)%-(%d+)')
		if date_year == nil or date_month == nil or date_day == nil then
			return nil
		end
		opts.path = vim.fs.joinpath(
			config.carlender_path,
			'year-' .. date_year,
			'month-' .. date_month,
			'day-' .. date_day .. '.md')
	elseif opts.path ~= nil then
		if not util.is_carlender_file(opts.path) then
			return nil
		end
		date_year = opts.date:match('year%-(%d+)')
		date_month = opts.date:match('month%-(%d+)')
		date_day = opts.date:match('day%-(%d+)')
		if date_year == nil or date_month == nil or date_day == nil then
			return nil
		end
		opts.date = table.concat({ date_year, date_month, date_day }, '-')
	end

	local dirname = vim.fs.dirname(opts.path)
	vim.loop.fs_mkdir(dirname, tonumber("744", 8))

	return setmetatable({
		date = opts.date,
		path = opts.path,
		content = "",
		appointments = {},
	}, self)
end

function Carlender:load(opts)
	local carlender = Carlender:from(opts)
	if carlender == nil then
		return nil
	end

	local file = io.open(carlender.path, 'r')
	if file ~= nil then
		carlender.content = file:read('*a')
		file:close()
	else
		carlender.content = ''
	end

	return carlender
end

function Carlender:today()
	local date = os.date('%Y-%m-%d')
	return Carlender:load({ date = date })
end

function Carlender:save()
end

function Carlender:edit()
	self:save()
	edit.edit_file(self.path)
end

function Carlender:file_exists()
	local stat = vim.loop.fs_stat(self.path)
	return stat ~= nil
end

function Carlender:_parse_appointments()
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

function Carlender:_reorder_appointments()
	table.sort(self.appointments, function(start, other)
		return start < other
	end)
end

return Carlender
