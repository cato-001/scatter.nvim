local config = {}

config.path = vim.fn.fnamemodify(vim.fs.normalize('~/notes'), ':p')
config.notes_path = vim.fn.fnamemodify(vim.fs.normalize(config.path .. '/notes'), ':p')
config.carlender_path = vim.fn.fnamemodify(vim.fs.normalize(config.path .. '/carlender'), ':p')

return config
