local Note = require('scatter.note')

local function get_tags(opts)
	if opts == nil then
		return ''
	end
	local tags = {}
	for _, value in ipairs(opts) do
		if value == 'date' then
			value = '#date-' .. os.date('%Y-%m-%d')
		elseif value == 'time' then
			value = '#time-' .. os.date('%H-%M')
		else
			value = '#' .. value
		end
		table.insert(tags, value)
	end
	return table.concat(tags, ' ')
end

return function(opts)
	local content = get_tags(opts)
	local note = Note:from_content(content)
	note:edit()
end
