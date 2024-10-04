local notes_setup = require('scatter.notes.setup')
local clean = require('scatter.notes.clean')
local edit = require('scatter.edit')
local util = require('scatter.util')

return function(opts)
	notes_setup(opts['notes'])

	clean.update_synonyms()
	clean.unify_timestamps()
	clean.split_notes()

	vim.api.nvim_create_autocmd('BufWritePost', {
		callback = function(opts)
			local path = opts['file']
			if not util.is_scatter_file(path) then
				return
			end
			clean.run_dprint()
			edit.reload_file()
		end
	})
end
