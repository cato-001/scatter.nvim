return function(opts)
	local notes_setup = require('scatter.note.setup')
	local calender_setup = require('scatter.calender.setup')
	local modules = require('scatter.modules')

	notes_setup(opts['notes'])
	calender_setup(opts['calender'])
	modules.setup(opts['modules'])

	vim.api.nvim_create_autocmd('BufEnter', {
		callback = function(event)
			local Source = require('scatter.source')
			Source:from_buffer(event.buf)
		end
	})
end
