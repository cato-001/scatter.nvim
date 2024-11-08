local util = require('scatter.util')
local config = require('scatter.config')

local M = {}

M.generate = function(date)
	local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	date = date or os.date('%Y-%m-%d')
	while true do
		local chars = {}
		for _ = 1, 20, 1 do
			local position = math.random(#charset)
			table.insert(chars, string.sub(charset, position, position))
		end
		local randstr = table.concat(chars, '')
		local name = date .. '_' .. randstr .. '.md'
		local path = vim.fs.joinpath(config.notes_path, name)
		if vim.loop.fs_stat(path) == nil then
			return name, path
		end
	end
end

return M
