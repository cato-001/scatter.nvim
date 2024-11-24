--- @param note Note
local function on_save(note)
	if not note:has_action('~pandoc-md') then
		return
	end
	if vim.fn.executable('pandoc') == 0 then
		print('pandoc is not installed')
		return
	end

	local lines = note.source:get_lines()
	if lines == nil then
		return
	end

	--- @type string
	local path
	--- @type string[]?
	local document = nil
	for _, line in ipairs(lines) do
		if document ~= nil then
			table.insert(document, line)
		elseif line:find('^~pandoc%-md') then
			path = line:match('^~pandoc%-md%s*([^%s]+)$')
			if path == nil then
				return
			end
			document = {}
		end
	end

	if document == nil then
		return
	end

	local config = require('scatter.config')

	path = path:gsub('%.pdf$', '') .. '.pdf'
	path = vim.fs.joinpath(config.path, path)

	local stdin = vim.loop.new_pipe(false)
	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)

	vim.loop.read_start(stdout, function(_, data)
		print(string.format('Output: %s', data))
	end)
	vim.loop.read_start(stderr, function(_, data)
		print(string.format('Error: %s', data))
	end)

	local handle
	handle = vim.loop.spawn('pandoc', {
		args = { '--read', 'markdown', '--output', path },
		stdio = { stdin, stdout, stderr },
	}, function(code)
		stdout:close()
		stderr:close()
		if handle ~= nil then
			handle:close()
		end

		if code ~= 0 then
			print('pandoc exited with code:', code)
		end
	end)

	stdin:write(table.concat(document, '\n'))
	stdin:close()
end

return {
	name = 'pandoc',
	types = { 'note' },
	on_save = on_save,
}
