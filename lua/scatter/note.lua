local config = require('scatter.config')
local edit = require('scatter.edit')
local tag = require('scatter.tag')
local util = require('scatter.util')
local generate_name = require('scatter.note.name').generate

local Note = {}
Note.__index = Note

function Note:load(name, path)
	if name == nil or name == '' then
		return nil
	end

	local note = setmetatable({
		name = name,
		path = path or vim.fs.joinpath(config.notes_path, name),
		bundle = tag.Bundle:empty()
	}, self)

	if not util.is_note_file(note.path) then
		return nil
	end

	local file = io.open(note.path)
	if not file then
		return nil
	end

	note.content = file:read('*a')
	file:close()

	note:_update()

	return note
end

function Note:from_content(content, date)
	local name, path = generate_name(date)
	local note = setmetatable({
		name = name,
		path = path,
		bundle = tag.Bundle:empty(),
		content = content,
	}, self)
	note:_update()
	return note
end

function Note:save()
	local file = io.open(self.path, 'w')
	if not file then
		error('could not save note: ' .. self.path)
	end
	file:write(self.content)
	file:close()
end

function Note:delete()
	os.remove(self.path)
end

function Note:edit()
	self:save()
	edit.edit_file(self.path)
end

function Note:_update()
	self.bundle:update_content(self.content)
end

function Note:get_date()
	local date = string.match(self.name, '^%d+%-%d+%-%d+')
	return date
end

function Note:match_all(needles)
	local result = 0
	for _, needle in ipairs(needles) do
		if self:match(needle) then
			result = result + 1
		end
	end
	return result == #needles, result
end

function Note:match_any(needles)
	for _, needle in ipairs(needles) do
		if self:match(needle) then
			return true
		end
	end
	return false
end

function Note:match(needle)
	for _, tag in ipairs(self.bundle.tags) do
		if string.find(tag, needle, nil, true) then
			return true
		end
	end
	return false
end

function Note:replace_tag(prev, new)
	self.content = tag.replace(self.content, prev, new)
	self:_update()
end

function Note:join_tags(sep)
	return table.concat(self.bundle.tags, sep)
end

function Note:has_tag(tag)
	return vim.list_contains(self.bundle.tags, tag)
end

function Note:find_tags(pattern)
	local tags = {}
	for _, tag in ipairs(self.bundle.tags) do
		if string.match(tag, pattern) then
			table.insert(tags, tag)
		end
	end
	return tags
end

function Note:has_action(action)
	return vim.list_contains(self.bundle.actions, action)
end

function Note:split()
	if not self:has_action('~split') then
		return false, { self }
	end
	local date = self:get_date()
	local notes = {}
	for content in vim.gsplit(self.content, '~split') do
		local note = Note:from_content(content, date)
		table.insert(notes, note)
	end
	return true, notes
end

function Note:run_code()
	if not self:has_action('~run') then
		return
	end

	for code_block in string.gmatch(self.content, '%s*```[^%s]+%s*~run[^`]+```') do
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
		self.content = string.gsub(self.content, code_block_pattern .. '%s*```output[^`]*```', code_block)

		local output_md = '```output\n' .. output .. '\n```'
		self.content = string.gsub(self.content, code_block_pattern, code_block .. '\n\n' .. output_md)
	end

	self:save()
end

function Note:generate_pandoc()
	if not self:has_action('~pandoc-md') then
		return
	end

	if vim.fn.executable('pandoc') == 0 then
		print('pandoc is not installed')
		return
	end

	local path, pandoc = string.match(self.content, '~pandoc%-md%s*([^%s]+)%s+(.+)')
	if path == nil or pandoc == nil then
		return
	end

	path = vim.fs.joinpath(config.path, path)

	local stdin = vim.loop.new_pipe(false)
	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)

	vim.loop.read_start(stdout, function(_, data)
		print(string.format("Output: %s", data))
	end)
	vim.loop.read_start(stderr, function(_, data)
		print(string.format("Error: %s", data))
	end)

	local handle
	handle = vim.loop.spawn('pandoc', {
		args = { '--read', 'markdown', '--output', path },
		stdio = { stdin, stdout, stderr },
	}, function(code)
		stdout:close()
		stderr:close()
		handle:close()

		if code ~= 0 then
			print('pandoc exited with code:', code)
		end
	end)

	stdin:write(pandoc)
	stdin:close()
end

return Note
