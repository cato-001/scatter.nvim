local function setup_today(opts)
	opts = opts or {}

	if opts.command ~= nil then
		vim.api.nvim_create_user_command(opts.command, function()
			local Day = require('scatter.carlender.day')
			local today = Day:today()
			today:edit()
		end, {})
	end
end

return function(opts)
	opts = opts or {}

	if opts.today ~= nil then
		setup_today(opts.today)
	end
end
