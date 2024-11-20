local function on_save(event)
	local path = event.file
	if path == nil then
		return
	end

	local modules = require('scatter.modules')

	local Source = require('scatter.source')
	local source = Source:from_file(path)

	local Note = require('scatter.note')
	local note = Note:from(source)
	modules.on_save(note, 'note')

	local Calender = require('scatter.calender')
	local calender = Calender:from(source)
	modules.on_save(calender, 'calender')
end

local function on_attatch(event)
	local Source = require('scatter.source')
	local modules = require('scatter.modules')

	local source = Source:from_buffer(event.buf)
	modules.attach_commands(source)
end

return function(opts)
	local notes_setup = require('scatter.note.setup')
	notes_setup(opts['notes'])

	local calender_setup = require('scatter.calender.setup')
	calender_setup(opts['calender'])

	local modules = require('scatter.modules')
	modules.setup(opts['modules'])

	local clean = require('scatter.note.clean')
	clean.update_synonyms()
	clean.unify_timestamps()
	clean.split_notes()

	vim.api.nvim_create_autocmd('BufWritePost', { callback = on_save })
	vim.api.nvim_create_autocmd('BufEnter', { callback = on_attatch })
end
