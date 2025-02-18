local M = {}

--- @class Module
--- @field should_run fun(type: string): boolean
--- @field on_save fun(obj: any)
--- @field commands table

--- @type table<string, Module>
M._modules = {}

M.setup = function(opts)
	if opts == nil then
		return
	end

	for _, module in ipairs(opts) do
		M.add(module)
	end

	--- @type table<string, string>
	local NAMED_MODULES = {
		jira = 'scatter.modules.jira',
		dprint = 'scatter.modules.dprint',
		scripting = 'scatter.modules.scripting',
		split = 'scatter.modules.split',
		pandoc = 'scatter.modules.pandoc',
	}

	for name, config in pairs(opts) do
		local module_path = NAMED_MODULES[name]
		if module_path == nil then
			error('wrong notes module defined in config: ' .. name)
		end
		local module = require(module_path)
		if type(module) ~= 'table' then
			error('module should be a table: ' .. module_path .. ' ' .. vim.inspect(module))
		end
		local setup = module.setup
		if setup ~= nil then
			setup(config)
		end
		M.add(module)
	end
end

--- @alias ModuleOpts { name: string, types: string[] | nil, should_run: (fun(type: string): boolean) | nil, on_save: fun(object: any) | nil, commands: table<string, fun(object: any)> | nil}

--- @param opts ModuleOpts
M.add = function(opts)
	opts = opts or {}
	local name = opts.name
	if name == nil then
		return
	end

	local run_for_types = opts.types or {}

	M._modules[name] = {
		should_run = opts.should_run or function(type)
			if next(run_for_types) == nil then
				return true
			end
			return vim.list_contains(run_for_types, type)
		end,
		on_save = opts.on_save or function() end,
		commands = opts.commands or {},
	}
end

--- @param name string
M.remove = function(name)
	M._modules[name] = nil
end

--- @param source Source?
M.on_save = function(source)
	if source == nil then
		return
	end

	local Note = require('scatter.note')
	local Calender = require('scatter.calendar')

	local note = Note:from(source)
	local calendar = Calender:from(source)

	for _, plugin in pairs(M._modules) do
		if note ~= nil and plugin.should_run('note') then
			plugin.on_save(note)
		end
		if calendar ~= nil and plugin.should_run('calendar') then
			plugin.on_save(calendar)
		end
	end
end

--- @param source Source
M.attach_commands = function(source)
	local buffer = source.buffer
	if buffer == nil then
		return
	end

	local Note = require('scatter.note')
	local Calender = require('scatter.calendar')

	local note = Note:from(source)
	local calendar = Calender:from(source)
	if note == nil and calendar == nil then
		return
	end

	for _, module in pairs(M._modules) do
		for name, callback in pairs(module.commands) do
			if note ~= nil and module.should_run('note') then
				vim.api.nvim_create_autocmd('BufWritePost', { callback = function() module.on_save(note) end })
				vim.api.nvim_buf_create_user_command(buffer, name, function() callback(note) end, {})
			elseif calendar ~= nil and module.should_run('calendar') then
				vim.api.nvim_create_autocmd('BufWritePost', { callback = function() module.on_save(calendar) end })
				vim.api.nvim_buf_create_user_command(buffer, name, function() callback(calendar) end, {})
			end
		end
		if note ~= nil and module.should_run('note') then
			vim.api.nvim_create_autocmd('BufWritePost', { callback = function() module.on_save(note) end })
		elseif calendar ~= nil and module.should_run('calendar') then
			vim.api.nvim_create_autocmd('BufWritePost', { callback = function() module.on_save(calendar) end })
		end
	end
end

return M
