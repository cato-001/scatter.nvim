local config = {}

config.path = vim.fs.normalize('~/scatter')
config.notes_path = vim.fs.normalize(config.path .. '/notes')
config.carlender_path = vim.fs.normalize(config.path .. '/carlender')

return config
