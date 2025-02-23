local function on_save()
	local config = require('scatter.config')

	if vim.fn.executable('dprint') == 0 then
		return
	end

	vim.system({ 'dprint', 'fmt' }, {
		cwd = config.path,
	})
end

return {
	name = 'dprint',
	types = { 'note' },
	on_save = on_save,
}
