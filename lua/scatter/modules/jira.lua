local JIRA_ACTION = '~jira'

--- @type fun(appointment: Appointment)
local commit = function(appointment) end

--- @param calender Calender
local function run_stage(calender)
	for _, appointment in ipairs(calender.appointments) do
		appointment:add_action(JIRA_ACTION)
	end
end

--- @param calender Calender
local function run_commit()
	for _, appointment in ipairs(carlender.appointments) do
		if appointment:has_action(JIRA_ACTION) then
			commit(appointment)
		end
	end
end

--- @type ModuleOpts
return {
	name = "jira",
	types = { 'carlender' },
	setup = function(opts)
		opts = opts or {}
		commit = opts.commit or function(appointment) end
	end,
	commands = {
		["JiraStage"] = run_stage,
		["JiraCommit"] = run_commit,
	}
}
