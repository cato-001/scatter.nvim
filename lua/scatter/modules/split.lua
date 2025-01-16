--- @param note Note
--- @return boolean, Note[]
local function split(note)
	if note == nil then
		return false, {}
	end
	if not note:has_action('~split') then
		return false, { note }
	end

	local date = note.source:get_date()
	if date == nil then
		return false, { note }
	end

	local lines = note.source:get_lines()
	if lines == nil then
		return false, { note }
	end

	local Note = require('scatter.note')

	--- @type Note[]
	local notes = {}
	local note_content = {}
	for _, line in ipairs(lines) do
		if line == '~split' then
			local part_note = Note:new(date)
			part_note.source:modify(function() return note_content end)
			table.insert(notes, part_note)
			note_content = {}
		else
			table.insert(note_content, line)
		end
	end

	return true, notes
end

return {
	name = 'split',
	types = {},
	on_save = split,
}
