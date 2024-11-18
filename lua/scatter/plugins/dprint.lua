local plugin = {}

plugin.types = { 'note' }

plugin.on_save = function()
	local config = require('scatter.config')

	if vim.fn.executable('dprint') == 0 then
		return
	end

	vim.system({ 'dprint', 'fmt' }, {
		cwd = config.path,
	})
end

return plugin
