-- lazy.lua — bootstrap lazy.nvim and load the specs in lua/plugins/.
-- Plugins live outside the nix store (~/.local/share/nvim/lazy) and are managed
-- in-editor with :Lazy — the nix side only provides nvim + the build toolchain
-- treesitter needs (see flake.nix).

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec = { { import = 'plugins' } },
  -- The flake deploys the config tree from the read-only Nix store.
  lockfile = vim.fn.stdpath('state') .. '/lazy-lock.json',
  install = { colorscheme = { 'wintry' } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
