local Note = {}

function Note:load(name)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.tags = {}

	local file = io.open(name)
	for line in file:lines() do
		for tag in string.gmatch(line, "#[a-zA-Z0-9][a-zA-Z0-9-_]+[a-zA-Z0-9]") do
			table.insert(obj.tags, tag)
		end
	end

	return obj
end

return Note
