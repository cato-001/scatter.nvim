local plugin = {}

plugin.types = { 'note' }

plugin.on_save = function(note)
	if not note:has_action('~run') then
		return
	end

	for code_block in string.gmatch(note.content, '%s*```[^%s]+%s*~run[^`]+```') do
		local lang, code = string.match(code_block, '```([^%s]+)%s*~run%s+(.+)```')

		local command = nil
		if lang == 'sh' then
			command = { 'sh', '-c', code }
		elseif lang == 'bash' then
			command = { 'bash', '-c', code }
		elseif lang == 'py' or lang == 'python' then
			command = { 'python3', '-c', code }
		elseif lang == 'lua' then
			command = { 'lua', '-e', code }
		elseif lang == 'js' or lang == 'javascript' then
			command = { 'node', '-e', code }
		else
			return
		end
		local output = vim.fn.system(command)

		local code_block_pattern = string.gsub(code_block, "([^%w])", "%%%1")
		note.content = string.gsub(note.content, code_block_pattern .. '%s*```output[^`]*```', code_block)

		local output_md = '```output\n' .. output .. '\n```'
		note.content = string.gsub(note.content, code_block_pattern, code_block .. '\n\n' .. output_md)
	end
end

return plugin
