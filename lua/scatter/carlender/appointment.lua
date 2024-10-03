local Appointment = {}

local function parseTimes(line)
	local hour, minute, raw_duration = string.match(line, '^(%d%d?):?(%d%d)?%s*([^%s].*[^%s])?%s*$')
	hour = tonumber(hour)
	minute = tonumber(minute)
	local start = {
		hour = hour,
		minute = minute,
	}

	local duration = 0
	local till_hour, till_minute = string.match(raw_duration, '^(%d%d?):?(%d%d)?$')
	if hour ~= nil and minute ~= nil then
		till_hour = tonumber(till_hour)
		till_minute = tonumber(till_minute)
		duration = (till_hour * 60 + till_minute) - (hour * 60 + minute)
	end
	local hours = string.match(raw_duration, '(%d+)h')
	if hours ~= nil then
		duration = duration + (tonumber(hours) * 60)
	end
	local minutes = string.match(raw_duration, '(%d+)h')
	if minutes ~= nil then
		duration = duration + tonumber(minutes)
	end

	return {
		start = start,
		duration = duration,
	}
end

function Appointment:new(opts)
	local appointment = setmetatable({
		start = opts.start,
		duration = opts.duration,
		comment = opts.comment,
	}, self)
	self.__index = self

	return appointment
end

function Appointment:take_parse(lines)
	local first = table.remove(lines, 1)
	local times = parseTimes(first)
	while true do
		local line = table.remove(lines, 1)
	end
end

return Appointment
