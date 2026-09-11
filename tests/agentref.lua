-- Run from the config directory: nvim --headless -u NONE -l tests/agentref.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.g.mapleader = ' '

local copied
vim.g.clipboard = {
  name = 'test',
  copy = {
    ['+'] = function(lines, regtype) copied = { lines, regtype } end,
    ['*'] = function() end,
  },
  paste = {
    ['+'] = function() return { { '' }, 'v' } end,
    ['*'] = function() return { { '' }, 'v' } end,
  },
}
local notifications = {}
vim.notify = function(message, level)
  notifications[#notifications + 1] = { message, level }
end
require('agentref').setup()
vim.api.nvim_buf_set_name(0, '/tmp/agent reference.lua')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three', 'four' })
vim.fn.setreg('0', 'previous yank')

local function expect(first, last, path)
  assert(vim.deep_equal(copied, {
    { string.format('%s:%d-%d', path or '/tmp/agent reference.lua', first, last) }, 'v',
  }), vim.inspect(copied))
  assert(vim.fn.getreg('0') == 'previous yank')
end

local function keys(input)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(input, true, false, true), 'xt', false)
end

vim.api.nvim_win_set_cursor(0, { 2, 0 })
keys(' ay')
expect(2, 2)
vim.cmd('1,4AgentRef')
expect(1, 4)

for _, mode in ipairs({ 'v', 'V', '<C-v>' }) do
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  keys(mode .. 'kk ay')
  expect(2, 4)
  assert(vim.fn.mode() == 'n')
end

local project = vim.fn.tempname()
local cwd = vim.fn.getcwd()
vim.fn.mkdir(project .. '/nested', 'p')
vim.fn.writefile({}, project .. '/nested/package.json')
-- A .git file also covers Git worktrees; Git wins over a nested package root.
vim.fn.writefile({ 'gitdir: /unused' }, project .. '/.git')
vim.api.nvim_buf_set_name(0, project .. '/nested/example.lua')
vim.cmd('1,4AgentRef')
expect(1, 4, 'nested/example.lua')
vim.fn.delete(project .. '/.git')
vim.cmd('1,4AgentRef')
expect(1, 4, 'example.lua')
vim.fn.delete(project .. '/nested/package.json')
vim.cmd.lcd(project)
vim.cmd('1,4AgentRef')
expect(1, 4, 'nested/example.lua')
vim.cmd.lcd(cwd)
vim.cmd('1,4AgentRef')
expect(1, 4, project .. '/nested/example.lua')
vim.fn.delete(project, 'rf')

copied = nil
vim.cmd.enew()
vim.cmd.AgentRef()
assert(copied == nil)
assert(notifications[#notifications][2] == vim.log.levels.WARN)
vim.api.nvim_buf_set_name(0, 'special-buffer')
vim.bo.buftype = 'nofile'
vim.cmd.AgentRef()
assert(copied == nil)
assert(notifications[#notifications][2] == vim.log.levels.WARN)
print('agentref tests passed')
