local util = require('scatter.util')
local config = require('scatter.config')

--- @class Synonyms
local Synonyms = {}

--- @return Synonyms
function Synonyms:load()
	local synonyms = setmetatable({
		path = vim.fs.joinpath(config.path, 'synonyms.txt'),
		values = {}
	}, self)
	self.__index = self

	local file = io.open(synonyms.path)
	if not file then
		return {}
	end
	local content = file:read('*a')
	file:close()

	for part in vim.gsplit(content, '===') do
		if part ~= '' then
			local synonym = {}
			for item in part:gmatch('[^%s]+') do
				item = item:gsub('^%s+', '')
				item = item:gsub('%s+$', '')
				table.insert(synonym, item)
			end
			if #synonym >= 2 then
				util.table_sort_without_duplicates(synonym)
				table.insert(synonyms.values, synonym)
			end
		end
	end

	return synonyms
end

function Synonyms:save()
	local file = io.open(self.path, 'w')
	if not file then
		error("could not save synonyms")
	end
	for _, synonyms in ipairs(self.values) do
		file:write('===\n')
		for _, synonym in ipairs(synonyms) do
			file:write(synonym)
			file:write('\n')
		end
	end
	file:close()
end

function Synonyms:remove_unused(tags)
	for index = #self.values, 1, -1 do
		local synonyms = self.values[index]
		local found = false
		for _, synonym in ipairs(synonyms) do
			if vim.list_contains(tags, synonym) then
				found = true
				break
			end
		end
		if not found then
			table.remove(self.values, index)
		end
	end
end

function Synonyms:get(tag)
	for _, synonym in ipairs(self.values) do
		if vim.list_contains(synonym, tag) then
			return true, synonym
		end
	end
	return false, {}
end

function Synonyms:find(needle)
	local result = {}
	for _, synonym in ipairs(self.values) do
		for _, item in ipairs(synonym) do
			if string.find(item, needle, nil, true) then
				vim.list_extend(result, synonym)
				break
			end
		end
	end
	return #result ~= 0, result
end

return Synonyms
