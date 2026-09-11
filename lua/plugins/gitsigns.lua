-- gitsigns — git state in the buffer itself: changed-line signs in the gutter
-- and blame for the line under the cursor. Complements lazygit (<leader>gg,
-- plugins/snacks.lua): lazygit answers "what is the state of the repo", gitsigns
-- answers "what did I change on this line, and who wrote the rest of it" without
-- leaving the buffer.
--
-- Loaded on BufReadPre rather than lazily on a key: both features are passive
-- displays, so there is no keystroke to hang them off — they have to already be
-- on when the file appears.
return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      -- Signs in the gutter, on by default (`signs` styling stays at the
      -- plugin's defaults). The sign column itself is pinned open in
      -- config/options.lua so lines don't shift the first time a hunk appears.
      signcolumn = true,

      -- Blame for the current line as virtual text at end-of-line.
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        -- Long enough that it doesn't strobe while moving through a file with
        -- the ×5 motions (N/E/I/O), short enough to feel immediate when you stop.
        delay = 300,
        ignore_whitespace = false,
      },
      -- Toggle it off for a session with `:Gitsigns toggle_current_line_blame`
      -- (e.g. narrow splits, where eol virtual text wraps).
    },
    -- No keymaps yet: hunk navigation and stage/reset need a home in the
    -- <leader>g tree, which is still an open decision alongside which-key.
    -- Everything is reachable meanwhile via `:Gitsigns <action>`.
  },
}
