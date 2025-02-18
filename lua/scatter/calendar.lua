local util = require('scatter.util')
local config = require('scatter.config')

--- @class Calender
--- @field source Source
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
	return setmetatable({
		source = source,
	}, self)
end

--- @param source Source
--- @return Calender | nil
function Calender:from(source)
	if not source:path_starts_with(config.calendar_path) then
		return nil
	end

	return setmetatable({
		source = source,
	}, self)
end

--- @return (fun(): Appointment?) | nil
function Calender:iter_appointments_rev()
	local paragraph_iter = self.source:iter_paragraphs_rev()
	if paragraph_iter == nil then
		return nil
	end

	local Appointment = require('scatter.calendar.appointment')
	--- @type Appointment?
	local prev = nil
	return function()
		for paragraph in paragraph_iter do
			local next = Appointment:from(paragraph)
			if next == nil then
				break
			end
			if prev ~= nil then
				if next.duration:is_empty() then
					next.duration = prev.start_time - next.start_time
				end
				local appointment = prev
				prev = next
				return appointment
			end
			prev = next
		end
		local appointment = prev
		prev = nil
		return appointment
	end
end

return Calender
