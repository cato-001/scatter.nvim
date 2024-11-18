local M = {}

M._plugins = {}

M.setup = function(opts)
	if opts == nil then
		return
	end

	for _, plugin in ipairs(opts) do
		M.add(plugin)
	end
end

M.add = function(opts)
	opts = opts or {}
	local name = opts[1]
	if name == nil then
		return nil
	end

	local run_for_types = opts.types or {}

	M._plugins[name] = {
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

M.remove = function(name)
	M._plugins[name] = nil
end

M.on_save = function(obj)
	local type = M.get_type(obj)
	for _, plugin in pairs(M._plugins) do
		if plugin.should_run(type) then
			plugin.on_save(obj)
		end
	end
end

M.attach_commands = function(buffer, type)
	local Carlender = require('scatter.carlender')

	for _, plugin in pairs(M._plugins) do
		print(vim.inspect(plugin), type)
		if plugin.should_run(type) then
			local commands = plugin.commands
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
