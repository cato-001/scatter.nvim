local function setup_today(opts)
	opts = opts or {}

	if opts.command ~= nil then
		local Day = require('scatter.carlender.day')

		vim.api.nvim_create_user_command(opts.command, function()
			local today = Day:today()
			today:edit()
		end, {})

		vim.api.nvim_create_user_command("JiraStage", function()
			local day = Day:today()
			day:_parse_appointments()
		end, {})
	end
end

return function(opts)
	opts = opts or {}

	if opts.today ~= nil then
		setup_today(opts.today)
	end
end
