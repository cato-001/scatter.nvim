local notes_setup = require('scatter.notes.setup')
local clean = require('scatter.notes.clean')

return function(opts)
	notes_setup(opts['notes'])

	clean.update_synonyms()
	clean.unify_timestamps()
	clean.split_notes()
end
