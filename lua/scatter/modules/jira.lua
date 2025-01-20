local JIRA_ACTION = '~jira'

--- @type fun(appointment: Appointment)
local commit = function(appointment)
	print('commit', vim.inspect(appointment.paragraph:get_bundle()), appointment:to_string_pretty())
end

--- @param calender Calender
local function run_stage(calender)
	for appointment in calender:iter_appointments_rev() do
		if appointment:has_tag('#work') then
			appointment:add_action(JIRA_ACTION)
		end
	end
end

--- @param calender Calender
local function run_commit(calender)
	--- @return Appointment?
	local function commit_next_appointment()
		local iter = calender:iter_appointments_rev()
		local appointment = nil
		for next in iter do
			if next:has_action(JIRA_ACTION) then
				appointment = next
				break
			end
		end
		if appointment == nil then
			return
		end
		commit(appointment)
		appointment:remove_action(JIRA_ACTION)
		vim.defer_fn(commit_next_appointment, 10)
	end
	vim.defer_fn(commit_next_appointment, 10)
end

--- @type ModuleOpts
return {
	name = "jira",
	types = { 'calender' },
	setup = function(opts)
		opts = opts or {}
		commit = opts.commit or commit
	end,
	commands = {
		["JiraStage"] = run_stage,
		["JiraCommit"] = run_commit,
	}
}
