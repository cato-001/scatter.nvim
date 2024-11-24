local Synonyms = require('scatter.note.synonyms')
local load_all_tags = require('scatter.tag').load_all_tags

local M = {}

M.update_synonyms = function()
	local tags = load_all_tags()
	local synonyms = Synonyms:load()

	synonyms:remove_unused(tags)
	local add_synonyms = {}
	for _, tag in ipairs(tags) do
		if not synonyms:get(tag) then
			table.insert(add_synonyms, { tag })
		end
	end

	vim.list_extend(synonyms.values, add_synonyms)
	synonyms:save()
end

M.unify_timestamps = function()
	local note_iter = require('scatter.note.iter')
	for note in note_iter() do
		local mapping = {}

		local tags = note:find_tags('^#202%d$')
		for _, tag in ipairs(tags) do
			mapping[tag] = string.gsub(tag, '(%d+)', 'year-%1')
		end

		tags = note:find_tags('^#202%d-%d%d?-%d%d?')
		for _, tag in ipairs(tags) do
			mapping[tag] = string.gsub(tag, '(%d+%-%d+%-%d+)', 'date-%1')
		end

		note:replace_tags(mapping)
	end
end

M.split_notes = function()
	local note_iter = require('scatter.note.iter')
	for note in note_iter() do
		-- local success, split_notes = note:split()
		-- if success then
		-- for _, split_note in ipairs(split_notes) do
		-- split_note:save()
		-- end
		-- note:delete()
		-- end
	end
end

return M
