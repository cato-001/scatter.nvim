local M = {}

local function generate_note_filename()
	local function generate()
		local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
		local chars = {}
		for _ = 1, 20, 1 do
			table.insert(chars, math.random(#charset))
		end
		local randstr = charset.char(table.unpack(chars))
		local date = os.date('%Y-%m-%d')
		return date .. '_' .. randstr .. '.md'
	end
	while true do
		local name = generate()
	end
end

local function get_tags(opts)
	if opts == nil then
		return ''
	end
	local tags = {}
	for _, value in ipairs(opts) do
		if value == 'date' then
			value = '#date-' .. os.date('%Y-%m-%d')
		elseif value == 'time' then
			value = '#time-' .. os.date('%H-%M')
		else
			value = '#' .. value
		end
		table.insert(tags, value)
	end
	return table.concat(tags, ' ')
end

M.create_note = function(opts)
	vim.cmd('vertical edit ' .. generate_note_filename())

	local window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(window, vim.o.columns)
	vim.api.nvim_win_set_height(window, vim.o.lines)

	local buffer = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { get_tags(opts), '', '' })
	vim.cmd.norm('G')
end

return M
