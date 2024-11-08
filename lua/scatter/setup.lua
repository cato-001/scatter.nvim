local notes_setup = require('scatter.note.setup')
local carlender_setup = require('scatter.carlender.setup')
local Note = require('scatter.note')
local Carlender = require('scatter.carlender')
local clean = require('scatter.note.clean')
local edit = require('scatter.edit')
local util = require('scatter.util')

return function(opts)
	notes_setup(opts['notes'])
	carlender_setup(opts['carlender'])

	clean.update_synonyms()
	clean.unify_timestamps()
	clean.split_notes()

	vim.api.nvim_create_autocmd('BufWritePost', {
		callback = function(event)
			local path = vim.fn.fnamemodify(event['file'], ':p')

			local carlender = Carlender:load(path)
			if carlender ~= nil then
				print('you are in a carlender')
				carlender:_parse_appointments()
				return
			end

			local name = vim.fs.basename(path)
			if name == nil then
				return
			end

			local note = Note:load(name)
			if note == nil then
				return
			end

			clean.run_dprint()
			note:run_code()

			edit.reload_file()
		end
	})
end
