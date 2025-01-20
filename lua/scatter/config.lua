local config = {}

config.path = vim.fn.fnamemodify(vim.fs.normalize('~/notes'), ':p')
config.notes_path = vim.fn.fnamemodify(vim.fs.normalize(config.path .. '/notes'), ':p')
config.calender_path = vim.fn.fnamemodify(vim.fs.normalize(config.path .. '/calender'), ':p')

return config
