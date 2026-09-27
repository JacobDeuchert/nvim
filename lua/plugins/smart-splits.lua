-- smart-splits.nvim — the nvim half of the Alt+neio nav (Principle 3).
--
-- smart-splits has no herdr backend, so the handoff is vendored from
-- vim-herdr-navigation (herdr/nvim-navigation/): herdr binds Alt+neio to that
-- plugin, which forwards the chord into this pane when nvim is in the
-- foreground; here we move between splits and, at an edge, tell herdr to focus
-- the neighbouring pane. Outside herdr ($HERDR_PANE_ID unset) the edge is a
-- plain stop, same as before. `multiplexer_integration = false` keeps
-- smart-splits from probing for tmux/wezterm/kitty.

-- Move one split in `dir`; at the edge, cross into the neighbouring herdr pane.
local function focus(dir)
  return function()
    local win = vim.api.nvim_get_current_win()
    require('smart-splits')['move_cursor_' .. dir]()
    local pane = vim.env.HERDR_PANE_ID
    if vim.api.nvim_get_current_win() == win and pane and pane ~= '' then
      -- Target our own pane: `--current` is herdr's globally focused pane.
      local herdr = vim.env.HERDR_BIN_PATH
      if not herdr or herdr == '' then herdr = 'herdr' end
      vim.system({ herdr, 'pane', 'focus', '--direction', dir, '--pane', pane })
    end
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
      -- Resize in the same 3-cell step the pane layer uses (herdr resize_pane_*).
      default_amount = 3,
    },
    keys = {
      -- focus: N E I O = ← ↓ ↑ →
      { '<M-n>', focus('left'),  desc = 'focus split/pane ←' },
      { '<M-e>', focus('down'),  desc = 'focus split/pane ↓' },
      { '<M-i>', focus('up'),    desc = 'focus split/pane ↑' },
      { '<M-o>', focus('right'), desc = 'focus split/pane →' },

      -- resize: Alt+Ctrl+neio (Principle 4 modifier escalation)
      { '<M-C-n>', '<cmd>SmartResizeLeft<cr>',  desc = 'resize split/pane ←' },
      { '<M-C-e>', '<cmd>SmartResizeDown<cr>',  desc = 'resize split/pane ↓' },
      { '<M-C-i>', '<cmd>SmartResizeUp<cr>',    desc = 'resize split/pane ↑' },
      { '<M-C-o>', '<cmd>SmartResizeRight<cr>', desc = 'resize split/pane →' },
    },
  },
}
