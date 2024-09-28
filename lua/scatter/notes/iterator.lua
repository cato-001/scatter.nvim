local config = require('scatter.config')
local Note = require('scatter.notes.note')

local NotesIterator = {}

function NotesIterator:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.handle = vim.loop.fs_scandir(config.notes_path)
	if not obj.handle then
		error("directory not found: " .. path)
	end
end

function NotesIterator:next_name()
	local name, _ = vim.loop.fs_scandir_next(self.handle)
	return name
end

function NotesIterator:next_note()
	local name, type = vim.loop.fs_scandir_next(self.handle)
	print()
end

return NotesIterator
