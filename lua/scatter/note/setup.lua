local function setup_commands(opts)
	if opts == nil then
		return
	end
	local create = opts['create']
	if create ~= nil then
		local create_note = require('scatter.note.create')
		for name, tags in pairs(create) do
			vim.api.nvim_create_user_command(name, function() create_note(tags) end, {})
		end
	end
	local commit = opts['commit']
	if commit then
		local commit_notes = require('scatter.commit').commit_notes
		vim.api.nvim_create_user_command(commit, commit_notes, {})
	end
end

local function setup_keymaps(opts)
	if opts == nil then
		return
	end
	local search = opts['search']
	if search ~= nil then
		local keys = table.remove(search, 1)
		local search_note = require('scatter.note.search')
		vim.keymap.set('n', keys, search_note, search)
	end
	local commit = opts['commit']
	if commit ~= nil then
		local keys = table.remove(commit, 1)
		local commit_notes = require('scatter.commit').commit_notes
		vim.keymap.set('n', keys, commit_notes, commit)
	end
end

return function(opts)
	opts = opts or {}
	setup_commands(opts['commands'])
	setup_keymaps(opts['keymaps'])
end
