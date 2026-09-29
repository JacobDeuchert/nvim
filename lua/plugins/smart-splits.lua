-- smart-splits.nvim — the nvim half of the Alt+neio nav (Principle 3).
--
-- herdr binds Alt+neio / Alt+Ctrl+neio to herdr/nvim-navigation (vendored from
-- vim-herdr-navigation), which forwards the chord into this pane when nvim is
-- in the foreground. Here we act on splits and, at an edge, hand over to herdr
-- by pane id. smart-splits' own herdr backend targets `--current` and passes
-- its cell amount as herdr's ratio, so `multiplexer_integration = false` and
-- the handoff lives here. Outside herdr ($HERDR_PANE_ID unset) an edge is a
-- plain stop.
--
-- Both layers share one resize model: Alt+Ctrl+<dir> moves the nearest border
-- in <dir> — the nvim split if there is one that way, else the herdr pane's.

local wincmd = { left = 'h', down = 'j', up = 'k', right = 'l' }
local opposite = { left = 'right', down = 'up', up = 'down', right = 'left' }

local function herdr(...)
  local bin = vim.env.HERDR_BIN_PATH
  if not bin or bin == '' then bin = 'herdr' end
  return { bin, ... }
end

-- Our own pane: `--current` is herdr's globally focused pane.
local function herdr_pane()
  local pane = vim.env.HERDR_PANE_ID
  if pane and pane ~= '' then return pane end
end

local function at_nvim_edge(dir)
  return vim.fn.winnr(wincmd[dir]) == vim.fn.winnr()
end

local function herdr_has_neighbor(pane, dir)
  local res = vim.system(herdr('pane', 'neighbor', '--direction', dir, '--pane', pane), { text = true }):wait()
  if res.code ~= 0 then return false end
  local ok, data = pcall(vim.json.decode, res.stdout)
  local neighbor = ok and data.result and data.result.neighbor
  return neighbor and type(neighbor.neighbor_pane_id) == 'string' or false
end

-- Move one split in `dir`; at the edge, cross into the neighbouring herdr pane.
local function focus(dir)
  return function()
    local win = vim.api.nvim_get_current_win()
    require('smart-splits')['move_cursor_' .. dir]()
    local pane = herdr_pane()
    if vim.api.nvim_get_current_win() == win and pane then
      vim.system(herdr('pane', 'focus', '--direction', dir, '--pane', pane))
    end
  end
end

-- Resize herdr's border when nvim has none in `dir` and herdr does, or when
-- nvim has no split on this axis at all (herdr then falls back to the
-- opposite border, as nvim would). Otherwise resize the nvim split.
local function resize(dir)
  return function()
    local pane = herdr_pane()
    if pane and at_nvim_edge(dir)
      and (at_nvim_edge(opposite[dir]) or herdr_has_neighbor(pane, dir)) then
      vim.system(herdr('pane', 'resize', '--direction', dir, '--pane', pane))
      return
    end
    require('smart-splits')['resize_' .. dir]()
  end
end

return {
  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    opts = {
      multiplexer_integration = false,
      -- Don't wrap around at the far edge of the outermost pane — wrapping makes
      -- "move left" occasionally jump right, which breaks the directional model.
      -- It also keeps the window unchanged at the edge, which is what focus()
      -- keys the herdr handoff on.
      at_edge = 'stop',
      -- Cells per press. herdr steps by its default ratio (0.05 of the tab).
      default_amount = 3,
    },
    keys = {
      -- focus: N E I O = ← ↓ ↑ →
      { '<M-n>', focus('left'),  desc = 'focus split/pane ←' },
      { '<M-e>', focus('down'),  desc = 'focus split/pane ↓' },
      { '<M-i>', focus('up'),    desc = 'focus split/pane ↑' },
      { '<M-o>', focus('right'), desc = 'focus split/pane →' },

      -- resize: Alt+Ctrl+neio (Principle 4 modifier escalation)
      { '<M-C-n>', resize('left'),  desc = 'resize split/pane ←' },
      { '<M-C-e>', resize('down'),  desc = 'resize split/pane ↓' },
      { '<M-C-i>', resize('up'),    desc = 'resize split/pane ↑' },
      { '<M-C-o>', resize('right'), desc = 'resize split/pane →' },
    },
  },
}
