local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local config = require('telescope.config').values
local Synonyms = require('scatter.notes.synonyms')

local _callable_obj = function()
	local obj = {}

	obj.__index = obj
	obj.__call = function(t, ...)
		return t:_find(...)
	end

	obj.close = function() end

	return obj
end

local NotesFinder = _callable_obj()

function NotesFinder:new(filters)
	filters = filters or {}

	local finder = setmetatable({
		notes = {},
		synonyms = Synonyms:load(),
	}, self)

	local NotesIterator = require('scatter.notes.iterator')
	for note in NotesIterator:new() do
		if note:match_all(filters) then
			table.insert(finder.notes, note)
		end
	end

	return finder
end

function NotesFinder:_find(prompt, process_result, process_complete)
	local needles = {}
	for needle in prompt:gmatch('[^%s]+') do
		table.insert(needles, needle)
		-- local _, synonyms = self.synonyms:find(needle)
		-- vim.list_extend(needles, synonyms)
	end

	for _, note in ipairs(self.notes) do
		if note:match_all(needles) then
			local tags = note:join_tags(' ')
			process_result({
				value = note.name,
				display = tags,
				ordinal = tags,
				path = note.path
			})
		end
	end

	process_complete()
end

local function notes_search_picker(opts)
	opts = opts or {}

	local finder = NotesFinder:new(opts['filters'])
	local sorter = config.generic_sorter(opts)
	local previewer = previewers.new_termopen_previewer({
		get_command = function(entry)
			return { 'bat', '-n', entry.path }
		end
	})

	pickers.new(opts, {
		prompt_title = 'Note Tags',
		finder = finder,
		sorter = sorter,
		previewer = previewer
	}):find()
end

return {
	search_note = notes_search_picker
}
