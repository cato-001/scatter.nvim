local config = {}

config.path = vim.fn.expand('~') .. '/scatter'
config.notes_path = config.path .. '/notes'
config.carlender_path = config.path .. '/carlender'

return config
