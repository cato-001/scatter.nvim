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
		date_year = opts.path:match('year%-(%d+)')
		date_month = opts.path:match('month%-(%d+)')
		date_day = opts.path:match('day%-(%d+)')
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

function Carlender:from_file(opts)
	local carlender = Carlender:from(opts)
	if carlender == nil then
		return nil
	end

	local file = io.open(carlender.path, 'r')
	if file ~= nil then
		local content = file:read('*a')
		file:close()
		carlender:_parse_appointments_from_text(content)
	end

	return carlender
end

function Carlender:from_buffer(buffer)
	local path = vim.api.nvim_buf_get_name(buffer)
	if path == nil then
		return nil
	end

	local carlender = Carlender:from({ path = path })
	if carlender == nil then
		return nil
	end

	local content = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	carlender:_parse_appointments_from_lines(content)

	return carlender
end

function Carlender:today()
	local date = os.date('%Y-%m-%d')
	return Carlender:from_file({ date = date })
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

function Carlender:_parse_appointments_from_text(text)
	local lines = {}

	for line in vim.gsplit(self.content, '\n', { plain = true }) do
		table.insert(lines, line)
	end

	self:_parse_appointments_from_lines(lines)
end

function Carlender:_parse_appointments_from_lines(lines)
	util.table_clear(self.appointments)

	local appointment = nil
	for _, line in ipairs(lines) do
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

	self:_reorder_appointments()
	self:_calculate_missing_appointment_duration()
end

function Carlender:_reorder_appointments()
	table.sort(self.appointments, function(appointment, other)
		return appointment.start_time < other.start_time
	end)
end

function Carlender:_calculate_missing_appointment_duration()
	for index, appointment in ipairs(self.appointments) do
		local next_appointment = self.appointments[index + 1]
		local missing_duration = appointment.duration == nil or appointment.duration:is_empty()
		if missing_duration and next_appointment ~= nil then
			appointment.duration = next_appointment.start_time - appointment.start_time
		end
	end
end

return Carlender
