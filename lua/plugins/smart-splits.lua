-- smart-splits.nvim — the nvim half of the Alt+neio nav (Principle 3).
--
-- DIFFERS FROM THE HOST on purpose. On the host, tmux forwards Alt+neio into
-- nvim when the active pane is vim (the `is_vim` if-shell check) and
-- smart-splits hands focus back to tmux at the edge. herdr 0.8.0 has neither:
-- no vim-aware navigation, no if-shell equivalent, and no smart-splits
-- multiplexer backend — see the "NOT PORTABLE" note in ~/.config/herdr/config.toml.
-- So under herdr these chords never reach nvim (herdr moves its own pane) and
-- edge handoff is impossible; `multiplexer_integration = false` keeps the
-- plugin from shelling out to a multiplexer that isn't there.
--
-- The binds are still worth having: they work whenever nvim runs outside a
-- herdr pane (plain `ssh devvm && nvim`). Split *focus* from inside a herdr
-- pane is still an open question — <C-w>neio is taken by split creation
-- (config/keymaps.lua), so it's <C-w>h/j/k/l or nothing for now.

return {
  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    opts = {
      -- No multiplexer backend for herdr (see above): pure nvim split moves.
      multiplexer_integration = false,
      -- Don't wrap around at the far edge of the outermost pane — wrapping makes
      -- "move left" occasionally jump right, which breaks the directional model.
      at_edge = 'stop',
      -- Resize in the same 3-cell step the pane layer uses (herdr resize_pane_*).
      default_amount = 3,
    },
    keys = {
      -- focus: N E I O = ← ↓ ↑ →
      { '<M-n>', '<cmd>SmartCursorMoveLeft<cr>',  desc = 'focus split/pane ←' },
      { '<M-e>', '<cmd>SmartCursorMoveDown<cr>',  desc = 'focus split/pane ↓' },
      { '<M-i>', '<cmd>SmartCursorMoveUp<cr>',    desc = 'focus split/pane ↑' },
      { '<M-o>', '<cmd>SmartCursorMoveRight<cr>', desc = 'focus split/pane →' },

      -- resize: Alt+Ctrl+neio (Principle 4 modifier escalation)
      { '<M-C-n>', '<cmd>SmartResizeLeft<cr>',  desc = 'resize split/pane ←' },
      { '<M-C-e>', '<cmd>SmartResizeDown<cr>',  desc = 'resize split/pane ↓' },
      { '<M-C-i>', '<cmd>SmartResizeUp<cr>',    desc = 'resize split/pane ↑' },
      { '<M-C-o>', '<cmd>SmartResizeRight<cr>', desc = 'resize split/pane →' },
    },
  },
}
