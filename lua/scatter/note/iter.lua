--- @param path string
--- @return (fun(): string?, string?) | nil
function iter_directory(path)
	local handle = vim.loop.fs_scandir(path)
	if handle == nil then
		return nil
	end
	return function()
		return vim.loop.fs_scandir_next(handle)
	end
end

--- @return fun(): Note?
return function()
	local config = require('scatter.config')

	local dir_iter = iter_directory(config.notes_path)
	if not dir_iter then
		error("directory not found: " .. config.notes_path)
	end

	local Source = require('scatter.source')
	local Note = require('scatter.note')
	return function()
		for name, type in dir_iter do
			if type == 'file' and string.find(name, "%.md$") then
				local path = vim.fs.joinpath(config.notes_path, name)
				local source = Source:from_file(path)
				local note = Note:from(source)
				if note ~= nil then
					return note
				end
			end
		end
	end
end
