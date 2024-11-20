--- @class Chunk
--- @field start integer
--- @field length integer
local Chunk = {}
Chunk.__index = Chunk

--- @param start integer
--- @param length integer
--- @return Chunk
function Chunk:new(start, length)
	return setmetatable({
		start = start,
		length = length,
	}, self)
end

--- @return Appointment | Todo | nil
function Chunk:get_object()

end

return Chunk
