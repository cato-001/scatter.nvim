local notes_setup = require('scatter.note.setup')
local carlender_setup = require('scatter.carlender.setup')
local Note = require('scatter.note')
local Carlender = require('scatter.carlender')
local clean = require('scatter.note.clean')
local util = require('scatter.util')

local function get_scatter_obj(path)
	local carlender = Carlender:from_file({ path = path })
	if carlender ~= nil then
		return carlender
	end
	return Note:load(path)
end

local function on_save(event)
	local plugins = require('scatter.plugins')

	local path = vim.fn.fnamemodify(event['file'], ':p')
	if path == nil then
		return
	end

	local obj = get_scatter_obj(path)
	if obj == nil then
		return
	end
	plugins.on_save(obj)
end

local function on_attatch(event)
	local plugins = require('scatter.plugins')

	local path = vim.fn.fnamemodify(event['file'], ':p')
	if path == nil then
		return
	end

	local obj = get_scatter_obj(path)
	if obj == nil then
		return
	end

	local buffer = event.buf
	local type = util.get_type(obj)
	plugins.attach_commands(buffer, type)
end

return function(opts)
	notes_setup(opts['notes'])
	carlender_setup(opts['carlender'])

	local plugins = require('scatter.plugins')
	plugins.setup(opts['plugins'])

	clean.update_synonyms()
	clean.unify_timestamps()
	clean.split_notes()

	vim.api.nvim_create_autocmd('BufWritePost', { callback = on_save })
	vim.api.nvim_create_autocmd('BufEnter', { callback = on_attatch })
end
