-- lazy.lua — bootstrap lazy.nvim and load the specs in lua/plugins/.
-- Plugins live outside the nix store (~/.local/share/nvim/lazy) and are managed
-- in-editor with :Lazy — the nix side only provides nvim + the build toolchain
-- treesitter needs (see flake.nix).

local uv = vim.uv or vim.loop

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not uv.fs_stat(lazypath) then
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

-- The lockfile exists twice, and only one of the two is authoritative.
--
-- lazy reads and writes a single path (Config.options.lockfile), so that path has
-- to be writable — and the flake deploys this tree from the read-only nix store,
-- where lazy's default (stdpath('config')/lazy-lock.json) cannot be written. The
-- live lockfile therefore lives in stdpath('state'), which is writable and is in
-- the dev VM's persistence set, so it survives a rebuild.
--
-- The copy versioned in this repo — shipped read-only next to init.lua — stays
-- the source of truth: it is what a fresh machine has to reproduce. Seed the
-- state copy from it whenever the shipped pins change. Without this the state
-- copy never comes into existence at all, and lazy's startup auto-install
-- (loader.lua: install{ lockfile = true }) quietly takes each plugin's branch
-- HEAD instead of the pinned commit.
--
-- Seeding compares content, not mtime: every file in the nix store has mtime
-- 1970-01-01, so timestamps carry no information here. The last-seeded content is
-- kept beside the lockfile, which makes the three cases unambiguous:
--   only the shipped copy changed — new pins were committed and deployed; take them
--   only the state copy changed   — a local `:Lazy update`; leave it alone
--   both changed                  — the repo wins, so carry local updates back first
--
-- To carry a local `:Lazy update` back into this repo:
--   cp ~/.local/state/nvim/lazy-lock.json <this repo>/lazy-lock.json
local state_dir = vim.fn.stdpath('state')
local lockfile = state_dir .. '/lazy-lock.json'
local shipped = vim.fn.stdpath('config') .. '/lazy-lock.json'
local seeded = state_dir .. '/lazy-lock.seed.json'

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local data = f:read('*a')
  f:close()
  return data
end

local function write_file(path, data)
  local f = io.open(path, 'w')
  if not f then
    return false
  end
  f:write(data)
  f:close()
  return true
end

local shipped_pins = read_file(shipped)
if shipped_pins and read_file(seeded) ~= shipped_pins then
  vim.fn.mkdir(state_dir, 'p')
  if write_file(lockfile, shipped_pins) then
    write_file(seeded, shipped_pins)
  end
end

require('lazy').setup({
  spec = { { import = 'plugins' } },
  lockfile = lockfile,
  install = { colorscheme = { 'wintry' } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
