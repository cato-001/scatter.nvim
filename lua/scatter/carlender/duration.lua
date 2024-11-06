local Duration = {}
Duration.__index = Duration

function Duration:new(hours, minutes)
	hours = hours or 0
	minutes = minutes or 0
	return setmetatable({
		hours = hours + math.floor(minutes / 60),
		minutes = minutes % 60,
	}, self)
end

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

function Duration:to_string_pretty()
	local parts = {}
	if self.hours ~= nil and self.hours ~= 0 then
		table.insert(parts, string.format('%dh', self.hours))
	end
	if self.minutes ~= nil and self.minutes ~= 0 then
		table.insert(parts, string.format('%dm', self.minutes))
	end
	return table.concat(parts, ' ')
end

return Duration
