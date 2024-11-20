--- @class Time
--- @field hours integer
--- @field minutes integer
local Time = {}
Time.__index = Time

--- @param hours number?
--- @param minutes number?
--- @return Time
function Time:new(hours, minutes)
	hours = hours or 0
	minutes = minutes or 0
	return setmetatable({
		hours = (hours + math.floor(minutes / 60)) % 24,
		minutes = minutes % 60
	}, self)
end

--- @param text string
--- @return Time?
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

--- @param other Duration
--- @return Time?
function Time:__add(other)
	local Duration = require('scatter.calender.duration')

	local metatable = getmetatable(other)
	if metatable == Duration then
		local minutes = self.minutes + other.minutes
		local hours = self.hours + other.hours
		return Time:new(hours, minutes)
	end
	return nil
end

--- @param other Time | Duration
--- @return Time | Duration | nil
function Time:__sub(other)
	local metatable = getmetatable(other)
	if metatable == Time then
		local minutes = self.minutes - other.minutes
		local hours = self.hours - other.hours
		return Duration:new(hours, minutes)
	end
	if metatable == Duration then
		local hours = self.hours - other.hours
		local minutes = self.minutes - other.minutes
		return Time:new(hours, minutes)
	end
	return nil
end

--- @param other Time
--- @return boolean
function Time:__lt(other)
	if getmetatable(other) ~= Time then
		return false
	end
	if self.hours < other.hours then
		return true
	end
	return self.hours == other.hours and self.minutes < other.minutes
end

--- @param other Time
--- @return boolean
function Time:__le(other)
	if getmetatable(other) ~= Time then
		return false
	end
	if self.hours < other.hours then
		return true
	end
	return self.hours == other.hours and self.minutes <= other.minutes
end

--- @param other Time
--- @return boolean
function Time:__gt(other)
	if getmetatable(other) ~= Time then
		return false
	end
	if self.hours > other.hours then
		return true
	end
	return self.hours == other.hours and self.minutes > other.minutes
end

--- @param other Time
--- @return boolean
function Time:__ge(other)
	if getmetatable(other) ~= Time then
		return false
	end
	if self.hours > other.hours then
		return true
	end
	return self.hours == other.hours and self.minutes >= other.minutes
end

--- @return string
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

--- @return string
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
