local notes_setup = require('scatter.notes.setup')
local carlender_setup = require('scatter.carlender.setup')
local Note = require('scatter.notes.note')
local clean = require('scatter.notes.clean')
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
			if not util.is_scatter_file(path) then
				return
			end
			clean.run_dprint()

			local name = vim.fs.basename(path)
			local note = Note:load(name)
			if note ~= nil then
				note:run_code()
			end

			edit.reload_file()
		end
	})
end
