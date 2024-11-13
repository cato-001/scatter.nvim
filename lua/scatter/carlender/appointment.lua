local tag = require('scatter.tag')
local Time = require('scatter.carlender.time')
local Duration = require('scatter.carlender.duration')

local Appointment = {}

function Appointment:from_times(line)
	local hour, minute, finish = string.match(line, '^(%d%d?)$')
	if hour == nil then
		hour, minute, finish = string.match(line, '^(%d%d?):?(%d%d)%s*(.*)$')
	end
	hour = tonumber(hour)
	minute = tonumber(minute)
	local start_time = Time:new(hour, minute)

	local duration = Duration:parse(finish)
	if duration == nil then
		local end_time = Time:parse(finish)
		if end_time ~= nil then
			duration = end_time - start_time
		end
	end

	local appointment = setmetatable({
		start_time = start_time,
		duration = duration,
		comments = {},
		bundle = tag.Bundle:empty()
	}, self)
	self.__index = self

	return appointment
end

function Appointment:add_comment(comment)
	self.bundle:add_content(comment)
	comment = tag.remove_all(comment)
	comment = string.gsub(comment, '^%s+', '')
	comment = string.gsub(comment, '%s+$', '')
	if comment ~= '' then
		table.insert(self.comments, comment)
	end
end

function Appointment:to_string_functional()
	local header = self.start_time:to_string_functional()
	if self.duration ~= nil then
		header = header .. ' ' .. self.duration:to_string()
	end
	local tags = self.bundle:to_string()
	if tags ~= '' then
		header = header .. '\n' .. tags
	end
	return table.concat({ header, unpack(self.comments) }, '\n')
end

function Appointment:to_string_pretty()
	local header = self.start_time:to_string_pretty()
	if self.duration ~= nil then
		header = header .. ' ' .. self.duration:to_string()
	end
	local tags = self.bundle:to_string()
	if tags ~= '' then
		header = header .. '\n' .. tags
	end
	return table.concat({ header, unpack(self.comments) }, '\n')
end

return Appointment
