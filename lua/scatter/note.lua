local config = require('scatter.config')

--- @class Note
--- @field source Source
--- @field todos Todo
local Note = {}
Note.__index = Note

--- @param date string?
--- @return Note
function Note:new(date)
	local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	local note_date = date or os.date('%Y-%m-%d')

	local filepath
	while true do
		local chars = {}
		for _ = 1, 20, 1 do
			local position = math.random(#charset)
			table.insert(chars, string.sub(charset, position, position))
		end
		local randstr = table.concat(chars, '')
		local filename = note_date .. '_' .. randstr .. '.md'
		filepath = vim.fs.joinpath(config.notes_path, filename)
		if vim.loop.fs_stat(filepath) == nil then
			break
		end
	end

	local Source = require('scatter.source')
	local source = Source:from_file(filepath)
	source:create_if_missing()

	return setmetatable({
		source = source,
		todos = {},
	}, self)
end

--- @param source Source
--- @return Note?
function Note:from(source)
	if not source:path_starts_with(config.notes_path) then
		return nil
	end

	return setmetatable({
		source = source,
		todos = {}
	}, self)
end

--- @param needles string[]?
--- @return boolean
function Note:match_all(needles)
	if needles == nil then
		return true
	end
	for _, needle in ipairs(needles) do
		if not self:match(needle) then
			return false
		end
	end
	return true
end

--- @param needles string[]
--- @return boolean
function Note:match_any(needles)
	for _, needle in ipairs(needles) do
		if self:match(needle) then
			return true
		end
	end
	return false
end

--- @param needle string
--- @return boolean
function Note:match(needle)
	local bundle = self.source:get_bundle()
	for _, tag in ipairs(bundle.tags) do
		if string.find(tag, needle, nil, true) then
			return true
		end
	end
	return false
end

--- @param mapping table<string, string>
function Note:replace_tags(mapping)
	if #mapping == 0 then
		return
	end
	local tag = require('scatter.tag')
	self.source:modify(function(lines)
		for index, line in ipairs(lines) do
			lines[index] = tag.replace(line, mapping)
		end
		return lines
	end)
end

--- @param name string
--- @return boolean
function Note:has_tag(name)
	local bundle = self.source:get_bundle()
	return vim.list_contains(bundle, name)
end

--- @param pattern string | number
--- @return string[]
function Note:find_tags(pattern)
	local bundle = self.source:get_bundle()
	local tags = {}
	for _, tag in ipairs(bundle) do
		if string.match(tag, pattern) then
			table.insert(tags, tag)
		end
	end
	return tags
end

--- @param action string
--- @return boolean
function Note:has_action(action)
	local bundle = self.source:get_bundle()
	return vim.list_contains(bundle, action)
end

--- @return string?
function Note:get_date()
	return self.source:get_date()
end

--- @return boolean, Note[]
function Note:split()
	if not self:has_action('~split') then
		return false, { self }
	end

	local date = self:get_date()
	if date == nil then
		return false, { self }
	end

	--- @type Note[]
	local notes = {}
	for content in vim.gsplit(self.content, '~split') do
		local note = Note:new(date)
		note.source:modify(function() return vim.split(content, '\n', { plain = true }) end)
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

	--- @type string?, string?
	local path, pandoc = string.match(self.content, '~pandoc%-md%s*([^%s]+)%s+(.+)')
	if path == nil or pandoc == nil then
		return
	end

	path = path:gsub('%.pdf$', '') + '.pdf'
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

	stdin:write(pandoc)
	stdin:close()
end

return Note
