local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local config = require('telescope.config').values

--- @class NoteFinder
--- @field notes Note[]
--- @field synonyms Synonyms
local NoteFinder = {}
NoteFinder.__index = NoteFinder

--- @param filters string[]?
--- @return NoteFinder
function NoteFinder:new(filters)
	local note_iter = require('scatter.note.iter')
	local Synonyms = require('scatter.note.synonyms')

	local notes = {}
	for note in note_iter() do
		if note:match_all(filters) then
			table.insert(notes, note)
		end
	end

	return setmetatable({
		notes = notes,
		synonyms = Synonyms:load(),
	}, self)
end

function NoteFinder:__call(prompt, process_result, process_complete)
	local needles = {}
	for needle in prompt:gmatch('[^%s]+') do
		table.insert(needles, needle)
		-- local _, synonyms = self.synonyms:find(needle)
		-- vim.list_extend(needles, synonyms)
	end

	for _, note in ipairs(self.notes) do
		if note:match_all(needles) then
			local bundle = note.source:get_bundle()
			local tags = table.concat(bundle.tags, ' ')
			process_result({
				value = note.source:get_name(),
				display = tags,
				ordinal = tags,
				path = note.source:get_path(),
			})
		end
	end

	process_complete()
end

function NoteFinder:close() end

--- @param opts { filters?: string[], }?
return function(opts)
	opts = opts or {}

	local finder = NoteFinder:new(opts.filters)
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
