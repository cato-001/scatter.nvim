local JIRA_ACTION = '~jira'

--- @type fun(appointment: Appointment)
local commit = function(appointment) end

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
	for _, appointment in ipairs(calender.appointments) do
		if appointment:has_action(JIRA_ACTION) then
			commit(appointment)
		end
	end
end

--- @type ModuleOpts
return {
	name = "jira",
	types = { 'calender' },
	setup = function(opts)
		opts = opts or {}
		commit = opts.commit or function(appointment) end
	end,
	commands = {
		["JiraStage"] = run_stage,
		["JiraCommit"] = run_commit,
	}
}
