local NotesIterator = require('scatter.notes.iterator')
local Synonyms = require('scatter.notes.synonyms')
local load_all_tags = require('scatter.notes.tag').load_all_tags

local M = {}

M.update_synonyms = function()
	local tags = load_all_tags()
	local synonyms = Synonyms:load()

	synonyms:remove_unused(tags)
	local add_synonyms = {}
	for _, tag in ipairs(tags) do
		if not synonyms:get_for_tag(tag) then
			table.insert(add_synonyms, { tag })
		end
	end

	vim.list_extend(synonyms.values, add_synonyms)

	synonyms:save()
end

M.unify_timestamps = function()
	local iter = NotesIterator:new()
	while true do
		local note = iter:next_note()
		if not note then
			break
		end

		local tags = note:find_tags('^#202%d$')
		for _, tag in ipairs(tags) do
			local new = string.gsub(tag, '(%d+)', 'year-%1')
			note:replace_tag(tag, new)
		end

		tags = note:find_tags('^#202%d-%d%d?-%d%d?')
		for _, tag in ipairs(tags) do
			local new = string.gsub(tag, '(%d+%-%d+%-%d+)', 'date-%1')
			print(new)
			note:replace_tag(tag, new)
		end

		note:save()
	end
end

M.split_notes = function()
	local iter = NotesIterator:new()
	while true do
		local note = iter:next_note()
		if not note then
			break
		end

		local success, split_notes = note:split()
		if success then
			for _, split_note in ipairs(split_notes) do
				split_note:save()
			end
			note:delete()
		end
	end
end

return M
