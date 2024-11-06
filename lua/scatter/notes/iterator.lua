local config = require('scatter.config')

local NotesIterator = {}

function NotesIterator:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.handle = vim.loop.fs_scandir(config.notes_path)
	if not obj.handle then
		error("directory not found: " .. config.notes_path)
	end

	return obj
end

function NotesIterator:__call()
	local name, type = nil, nil
	while true do
		name, type = vim.loop.fs_scandir_next(self.handle)
		if name == nil then
			return nil
		end
		if type == 'file' and string.find(name, "%.md$") then
			break
		end
	end
	return require('scatter.notes.note'):load(name)
end

function NotesIterator:collect_notes(notes)
	for note in self do
		table.insert(notes, note)
	end
end

return NotesIterator
