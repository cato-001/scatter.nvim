return function(opts)
	local notes_setup = require('scatter.note.setup')
	local calendar_setup = require('scatter.calendar.setup')
	local modules = require('scatter.modules')

	notes_setup(opts['notes'])
	calendar_setup(opts['calendar'])
	modules.setup(opts['modules'])

	vim.api.nvim_create_autocmd('BufEnter', {
		callback = function(event)
			local Source = require('scatter.source')
			Source:from_buffer(event.buf)
		end
	})
end
