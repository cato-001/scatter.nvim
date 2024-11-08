local config = require('scatter.config')

local NoteIterator = {}

function NoteIterator:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.handle = vim.loop.fs_scandir(config.notes_path)
	if not obj.handle then
		error("directory not found: " .. config.notes_path)
	end

	return obj
end

function NoteIterator:__call()
	local Note = require('scatter.note')
	local name, type = nil, nil
	while true do
		name, type = vim.loop.fs_scandir_next(self.handle)
		if name == nil then
			return nil
		end
		if type == 'file' and string.find(name, "%.md$") then
			local note = Note:load(name)
			if note ~= nil then
				return note
			end
		end
	end
end

function NoteIterator:collect_notes(notes)
	for note in self do
		table.insert(notes, note)
	end
end

return NoteIterator
