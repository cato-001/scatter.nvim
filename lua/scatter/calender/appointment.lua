local tag = require('scatter.tag')

--- @class Appointment
--- @field paragraph Paragraph
--- @field start_time Time
--- @field duration Duration
--- @field comments_cache string[]?
--- @field comments_cache_version integer
local Appointment = {}
Appointment.__index = Appointment

--- @param value string
--- @return Time?
--- @return Duration?
local function parse_time_with_duration(value)
	local Time = require('scatter.calender.time')
	local Duration = require('scatter.calender.duration')

	local hour, minute, finish = string.match(value, '^(%d%d?)$')
	if hour == nil then
		hour = string.match(value, '^(%d%d?)%s')
	end
	if hour == nil then
		hour, minute, finish = string.match(value, '^(%d%d?):?(%d%d)%s+(.*)$')
	end
	local start_time = Time:new(tonumber(hour), tonumber(minute))
	if start_time == nil then
		return nil, nil
	end

	local duration = Duration:parse(finish)
	if duration == nil then
		local end_time = Time:parse(finish)
		if end_time ~= nil then
			duration = end_time - start_time
		end
	end
	duration = duration or Duration:new(0, 0)

	return start_time, duration
end

--- @param paragraph Paragraph?
--- @return Appointment?
function Appointment:from(paragraph)
	if paragraph == nil then
		return nil
	end
	local lines = paragraph:get_lines()
	if lines == nil then
		return nil
	end

	--- @type string
	local first = lines[1]
	local time, duration = parse_time_with_duration(first)
	if time == nil then
		return nil
	end

	return setmetatable({
		paragraph = paragraph,
		start_time = time,
		duration = duration,
	}, self)
end

--- @return string[]?
function Appointment:get_comments()
	if self.comments_cache ~= nil and self.comments_cache_version == self.paragraph.lines_cache_version then
		return self.comments_cache
	end
	local lines = self.paragraph:get_lines()
	if lines == nil then
		return nil
	end
	self.comments_cache_version = self.paragraph.lines_cache_version
	self.comments = {}
	for index = 2, #lines do
		local line = lines[index]
		line = tag.remove_all(line)
		if line ~= '' then
			self.comments[#self.comments + 1] = line
		end
	end
	return self.comments
end

--- @param name string
--- @return boolean
function Appointment:has_tag(name)
	local bundle = self.paragraph:get_bundle()
	if bundle == nil then
		return false
	end
	return vim.list_contains(bundle.tags, name)
end

--- @param name string
--- @return boolean
function Appointment:has_action(name)
	local bundle = self.paragraph:get_bundle()
	if bundle == nil then
		return false
	end
	return vim.list_contains(bundle.actions, name)
end

--- @param name string
function Appointment:add_action(name)
	if self:has_action(name) then
		return
	end
	local bundle = self.paragraph:get_bundle()
	if bundle == nil then
		return
	end
	table.insert(bundle.actions, name)
	self.paragraph:modify(function(lines)
		local new_lines = self:get_lines({
			bundle = bundle,
		})
		return new_lines or lines
	end)
end

--- @param name string
function Appointment:remove_action(name)
	if not self:has_action(name) then
		return
	end
	local bundle = self.paragraph:get_bundle()
	if bundle == nil then
		return
	end
	for i = #bundle.actions, 1, -1 do
		if bundle.actions[i] == name then
			table.remove(bundle.actions, i)
		end
	end
	self.paragraph:modify(function(lines)
		local new_lines = self:get_lines({
			bundle = bundle,
		})
		return new_lines or lines
	end)
end

--- @param changes {bundle: Bundle?}?
--- @return string[]?
function Appointment:get_lines(changes)
	changes = changes or {}
	local header = self.start_time:to_string_functional()
	if not self.duration:is_empty() then
		header = header .. ' ' .. self.duration:to_string()
	end
	local bundle = changes.bundle or self.paragraph:get_bundle()
	if bundle == nil then
		return nil
	end
	local tags = bundle:get_lines()
	local comments = self:get_comments()
	if comments == nil then
		return nil
	end
	local lines = { header }
	vim.list_extend(lines, tags)
	vim.list_extend(lines, comments)
	return lines
end

function Appointment:to_string_pretty()
	local header = self.start_time:to_string_pretty()
	if self.duration ~= nil then
		header = header .. ' ' .. self.duration:to_string()
	end
	local bundle = self.paragraph:get_bundle()
	if bundle == nil then
		return nil
	end
	local tags = bundle:to_string()
	if tags ~= '' then
		header = header .. '\n' .. tags
	end
	local comments = self:get_comments()
	if comments == nil then
		return nil
	end
	return table.concat({ header, unpack(comments) }, '\n')
end

return Appointment
