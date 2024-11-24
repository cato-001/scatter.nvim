--- @param note Note
local function on_save(note)
	if not note:has_action('~run') then
		return
	end

	for code_block in note:iter_code_rev() do
		local lang, code = code_block:get_language(), code_block:get_content()

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
		output = string.gsub(output, '^%s*', '')
		output = string.gsub(output, '%s*$', '')
		local output_lines = vim.split(output, '\n', { plain = true })
		table.insert(output_lines, 1, '~output')

		local paragraph = note.source:get_paragraph_after(code_block.end_line + 1)
		if paragraph == nil then
			note.source:append(output_lines)
			return
		end
		local is_output = paragraph:has_action('~output')
		paragraph:modify(function(lines)
			if is_output then
				return output_lines
			end
			local new_lines = {}
			vim.list_extend(new_lines, output_lines)
			if #lines ~= 0 then
				table.insert(new_lines, '')
				vim.list_extend(new_lines, lines)
			end
			return new_lines
		end)
	end
end

return {
	name = 'scripting',
	types = { 'note' },
	on_save = on_save,
}
