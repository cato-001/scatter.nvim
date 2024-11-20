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

	for name, config in pairs(opts) do
		if name == "jira" then
			local JiraModule = require('scatter.modules.jira')
			JiraModule.setup(config)
			M.add(JiraModule)
		end
	end
end

--- @alias ModuleOpts {
---     name: string,
---     types: string[] | nil,
---     should_run: (fun(type: string): boolean) | nil,
---     on_save: fun(object: any) | nil,
---     commands: table<string, fun(object: any)> | nil}

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

--- @param obj Note | Calender | nil
--- @param obj_type 'note' | 'calender'
M.on_save = function(obj, obj_type)
	if obj == nil then
		return
	end

	for _, plugin in pairs(M._modules) do
		if plugin.should_run(obj_type) then
			plugin.on_save(obj)
		end
	end
end

--- @param source Source
M.attach_commands = function(source)
	if true then
		return
	end
	local Carlender = require('scatter.calender')

	for _, module in pairs(M._modules) do
		print(vim.inspect(module), type)
		if module.should_run(type) then
			local commands = module.commands
			for name, callback in pairs(commands) do
				vim.api.nvim_buf_create_user_command(buffer, name, function()
					local carlender = Carlender:from_buffer(buffer)
					if carlender == nil then
						return
					end
					callback(carlender)
				end, {})
			end
		end
	end
end

return M
