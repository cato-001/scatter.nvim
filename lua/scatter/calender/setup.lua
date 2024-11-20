local function setup_today(opts)
	opts = opts or {}

	if opts.command ~= nil then
		local Carlender = require('scatter.calender')

		vim.api.nvim_create_user_command(opts.command, function()
			local today = Carlender:today()
			if today ~= nil then
				today:edit()
			end
		end, {})
	end
end

return function(opts)
	opts = opts or {}

	if opts.today ~= nil then
		setup_today(opts.today)
	end
end
