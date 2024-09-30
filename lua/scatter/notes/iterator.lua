local config = require('scatter.config')
local Note = require('scatter.notes.note')

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

function NotesIterator:next_name()
	while true do
		local name, type = vim.loop.fs_scandir_next(self.handle)

		if name == nil then
			return nil
		end

		if type == 'file' and string.find(name, "%.md$") then
			return name
		end
	end
end

function NotesIterator:next_note()
	local name = self:next_name()
	if name == nil then
		return nil
	end
	return Note:load(name)
end

function NotesIterator:collect_notes(notes)
	while true do
		local note = self:next_note()
		if not note then
			return
		end
		table.insert(notes, note)
	end
end

return NotesIterator
