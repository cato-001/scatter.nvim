local Duration = require('scatter.carlender.duration')

local Time = {}
Time.__index = Time

function Time:new(hours, minutes)
	hours = hours or 0
	minutes = minutes or 0
	return setmetatable({
		hours = (hours + math.floor(minutes / 60)) % 24,
		minutes = minutes % 60
	}, self)
end

function Time:parse(text)
	if text == nil then
		return nil
	end
	local hour, minute = string.match(text, '^(%d%d?):?(%d%d)?$')
	if hour == nil or minute == nil then
		return nil
	end
	return Time:new(tonumber(hour), tonumber(minute))
end

function Time:__add(other)
	if other.__index == Duration then
		local minutes = self.minutes + other.minutes
		local hours = self.hours + other.hours
		return Time:new(hours, minutes)
	end
	return nil
end

function Time:__sub(other)
	if other.__index == Time then
		local minutes = self.minutes - other.minutes
		local hours = self.hours - other.hours
		Duration:new(hours, minutes)
	end
	return nil
end

function Time:_fix_overflow()
end

function Time:total_minutes()
	return self.hours * 60 + self.minutes
end

function Time:to_string_pretty()
	local result = ''
	if self.hours < 10 then
		result = result .. '0'
	end
	result = result .. tostring(self.hours) .. ':'
	if self.minutes < 10 then
		result = result .. '0'
	end
	return result .. tostring(self.minutes)
end

function Time:to_string_functional()
	local result = tostring(self.hours)
	if self.minutes == 0 then
		return result
	end
	if self.minutes < 10 then
		result = result .. '0'
	end
	return result .. tostring(self.minutes)
end

return Time
