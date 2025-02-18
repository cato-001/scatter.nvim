local config = {}

config.path = vim.fn.fnamemodify(vim.fs.normalize('~/notes'), ':p')
config.notes_path = vim.fn.fnamemodify(vim.fs.normalize(config.path .. '/notes'), ':p')
config.calendar_path = vim.fn.fnamemodify(vim.fs.normalize(config.path .. '/calendar'), ':p')

return config
