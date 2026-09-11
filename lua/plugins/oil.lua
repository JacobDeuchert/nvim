-- oil.nvim — the file explorer on <leader>e (04-neovim.md).
-- Picked over a sidebar tree because oil renders a directory as an *ordinary
-- editable buffer*: the n/e/i/o motion layer keeps working inside it (a tree's
-- buffer-local single-letter binds would shadow it — Principle 4), and file ops
-- are just text edits — `dd` deletes, retype a name to rename, new line to
-- create, `:w` commits the batch.
return {
  {
    'stevearc/oil.nvim',
    -- Not lazy: oil takes over netrw, which has to happen before anything opens
    -- a directory (e.g. `nvim .`).
    lazy = false,
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true, -- dotfiles are half this repo
      },
    },
    keys = {
      { '<leader>e', '<cmd>Oil<cr>', desc = 'file explorer (oil)' },
    },
  },
}
