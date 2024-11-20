--- @class Duration
--- @field hours integer
--- @field minutes integer
local Duration = {}
Duration.__index = Duration

--- @param hours number?
--- @param minutes number?
--- @return Duration
function Duration:new(hours, minutes)
	hours = hours or 0
	minutes = minutes or 0
	return setmetatable({
		hours = hours + math.floor(minutes / 60),
		minutes = minutes % 60,
	}, self)
end

--- @param text string
--- @return Duration?
function Duration:parse(text)
	if text == nil then
		return nil
	end
	local hours = string.match(text, '(%d+)h')
	local minutes = string.match(text, '(%d+)m')
	if hours == nil and minutes == nil then
		return nil
	end
	return self:new(hours, minutes)
end

--- @return string
function Duration:to_string()
	local parts = {}
	if self.hours ~= nil and self.hours ~= 0 then
		table.insert(parts, string.format('%dh', self.hours))
	end
	if self.minutes ~= nil and self.minutes ~= 0 then
		table.insert(parts, string.format('%dm', self.minutes))
	end
	return table.concat(parts, ' ')
end

--- @return boolean
function Duration:is_empty()
	return self.hours == nil and self.minutes == nil
end

return Duration
