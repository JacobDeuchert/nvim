-- options.lua — minimal sane defaults. Expand as the config grows.
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = 'a'
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.scrolloff = 4
opt.showmode = false -- lualine displays the current mode

-- Always show the sign column. With the default "auto" it appears the moment
-- the first gitsigns hunk or LSP diagnostic lands and shoves the whole buffer
-- one column right, mid-edit; pinning it open trades one column for a text
-- position that never moves.
opt.signcolumn = 'yes'

-- Splits open right/below by default; the directional <C-w> binds in keymaps.lua
-- set the direction explicitly regardless, but this keeps stray :split sane.
opt.splitright = true
opt.splitbelow = true

-- Treesitter folds are wired up per buffer (lua/plugins/treesitter.lua); keep
-- everything unfolded on open so they're there when asked for and never in the way.
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Use the local Wayland provider when available. On the VM, OSC 52 sends yanks
-- through SSH to the terminal on this machine instead. SSH_CONNECTION survives
-- multiplexer sessions where SSH_TTY may not.
if vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
  local osc52 = require('vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'osc52',
    copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
    paste = {
      ['+'] = function() return vim.split(vim.fn.getreg('"'), '\n') end,
      ['*'] = function() return vim.split(vim.fn.getreg('"'), '\n') end,
    },
  }
end
opt.clipboard = 'unnamedplus'
