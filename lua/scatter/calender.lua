local util = require('scatter.util')
local Appointment = require('scatter.calender.appointment')
local config = require('scatter.config')

--- @class Calender
--- @field source Source
--- @field appointments Appointment[]
local Calender = {}
Calender.__index = Calender

--- @return Calender | nil
function Calender:today()
	local Source = require('scatter.source')
	local date = os.date('%Y-%m-%d')
	if type(date) ~= 'string' then
		error('could not get date')
	end
	local source = Source:from_date(date)
	source:create_if_missing()
	return Calender:from(source)
end

--- @param source Source
--- @return Calender | nil
function Calender:from(source)
	if not source:path_starts_with(config.carlender_path) then
		return nil
	end

	return setmetatable({
		source = source,
		appointments = {},
	}, self)
end

function Calender:open()
	self.source:open()
end

function Calender:file_exists()
	local stat = vim.loop.fs_stat(self.path)
	return stat ~= nil
end

--- @return nil
function Calender:_parse_appointments()
	local content = self.source:_get_lines()
	if content == nil or #content == 0 then
		return
	end

	util.table_clear(self.appointments)

	local appointment = nil
	for _, line in ipairs(content) do
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

function Calender:_reorder_appointments()
	table.sort(self.appointments, function(appointment, other)
		return appointment.start_time < other.start_time
	end)
end

function Calender:_calculate_missing_appointment_duration()
	for index, appointment in ipairs(self.appointments) do
		local next_appointment = self.appointments[index + 1]
		local missing_duration = appointment.duration == nil or appointment.duration:is_empty()
		if missing_duration and next_appointment ~= nil then
			appointment.duration = next_appointment.start_time - appointment.start_time
		end
	end
end

return Calender
