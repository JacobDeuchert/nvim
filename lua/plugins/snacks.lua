-- snacks.nvim — a collection of small independent modules. Every module is off
-- unless it's given `enabled = true`, so this stays a one-module install: lazygit
-- in a float. Turn others on here as they're decided (04-neovim.md decision 3).
return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      lazygit = {
        enabled = true,
        win = {
          width = 0.95,
          height = 0.95,
        },
        -- snacks generates a lazygit theme from the active colorscheme (wintry)
        -- and passes it with `-ucf`, leaving your own lazygit config untouched.
        configure = true,
      },
    },
    keys = {
      -- Lands in the <leader>g git tree (04-neovim.md). `gg` = the full UI;
      -- Snacks.lazygit.log() and .log_file() are there if the tree wants them.
      { '<leader>gg', function() Snacks.lazygit() end, desc = 'lazygit' },
    },
  },
}
