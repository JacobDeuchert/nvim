-- telescope — the finder (files + buffers). The explorer is oil on <leader>e;
-- telescope answers "I know the name, take me there", oil answers "show me the
-- tree / do file operations".
--
-- Both pickers live on Ctrl chords, not <leader>: <leader> is unreachable from
-- insert mode (Space is a literal space there), so a Ctrl chord is the only kind
-- of bind that works in both modes — the pickers are "jump somewhere else", which
-- you want mid-typing as much as from normal. <C-e> also echoes zsh, where ^E is
-- the fuzzy project jump (ji-widget, nixos/zsh.nix): Ctrl+E = "fuzzy-jump to a thing" at
-- whichever layer you're in. Ctrl stays free for shells/TUIs (Principle 3) — this
-- only claims chords inside nvim.
--
-- What they cost: <C-b> was page-up (redundant next to <C-u>/<C-d> half-page and
-- the ×5 motions), <C-e> was scroll-one-line-down.
--
-- find_files shells out to the first of fd/rg it finds — ripgrep comes from
-- flake.nix, so the picker respects .gitignore without extra
-- config. Without it telescope falls back to plain `find`, which walks
-- node_modules/bin/obj.
return {
  {
    'nvim-telescope/telescope.nvim',
    -- master, not the 0.1.x release branch: 0.1.x's previewer highlights via
    -- nvim-treesitter's `parsers.ft_to_lang()`, which the treesitter rewrite
    -- (main branch, see treesitter.lua) deleted — every preview threw
    -- "attempt to call field 'ft_to_lang' (a nil value)". master highlights with
    -- the native vim.treesitter.language.get_lang() and needs no nvim-treesitter.
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'Telescope',
    keys = {
      -- stopinsert keeps closing a picker from restoring an abandoned insert.
      { '<C-e>', '<cmd>stopinsert<cr><cmd>Telescope find_files<cr>', mode = { 'n', 'i' }, desc = 'find files' },
      { '<C-f>', '<cmd>stopinsert<cr><cmd>Telescope live_grep<cr>',  mode = { 'n', 'i' }, desc = 'search files' },
      { '<leader>sw', '<cmd>Telescope grep_string<cr>', desc = 'search word' },
      { '<C-b>', '<cmd>stopinsert<cr><cmd>Telescope buffers<cr>',    mode = { 'n', 'i' }, desc = 'buffers' },
    },
    -- opts as a function so requiring telescope.actions doesn't drag the plugin
    -- in at startup.
    opts = function()
      local actions = require('telescope.actions')
      return {
        defaults = {
          -- The prompt runs in insert mode, so the motion layer doesn't apply:
          -- <C-n>/<C-p> move the selection, <Esc> drops to the picker's normal mode.
          layout_strategy = 'flex',
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          buffers = {
            -- Most-recent first, so the top entry is the buffer you just came
            -- from — <leader>b <CR> becomes a fast alternate-buffer toggle.
            sort_mru = true,
            sort_lastused = true,
            mappings = {
              -- Close buffers without leaving the picker; move_to_top keeps the
              -- selection sane so you can delete several in a row.
              i = { ['<C-d>'] = actions.delete_buffer + actions.move_to_top },
              n = { ['<C-d>'] = actions.delete_buffer + actions.move_to_top },
            },
          },
        },
      }
    end,
  },
}
