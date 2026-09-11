-- lualine — the statusline. What it is here for: mode, file, git state,
-- diagnostics, position. Everything on it is information the buffer itself
-- doesn't already show.
--
-- theme = 'auto' rather than 'wintry': lualine's auto resolves
-- `lualine.themes.<colorscheme>` first, and wintry-theme ships exactly that
-- (lua/lualine/themes/wintry.lua, see its README), so this picks up the real
-- theme today and keeps working if the colorscheme is ever swapped — naming
-- 'wintry' explicitly would hard-fail on that swap instead.
--
-- Loaded eagerly (lazy = false, VeryLazy is the usual choice): a statusline that
-- appears a beat after the first buffer redraws the whole frame, and there is no
-- keystroke or event to hang it off since it is always visible.
return {
  {
    'nvim-lualine/lualine.nvim',
    -- Filetype/mode icons. lualine degrades to text-only without it, but the
    -- terminal is kitty with a nerd font (host side), so the glyphs render.
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    opts = {
      options = {
        theme = 'auto',
        -- One statusline for the whole window instead of one per split. With
        -- smart-splits (plugins/smart-splits.lua) splits are cheap and there
        -- are usually several open; per-split lines then repeat the same git
        -- branch and mode 3× and eat a row from each pane.
        globalstatus = true,
        -- Powerline separators need a nerd font in every terminal that ever
        -- attaches to this nvim, including a bare TTY. Plain sections do not.
        section_separators = '',
        component_separators = '|',
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = {
          'branch',
          -- Sourced from gitsigns (plugins/gitsigns.lua), which is already
          -- tracking the buffer, rather than lualine shelling out to `git
          -- diff` on its own timer.
          {
            'diff',
            source = function()
              local gs = vim.b.gitsigns_status_dict
              if gs then
                return { added = gs.added, modified = gs.changed, removed = gs.removed }
              end
            end,
          },
        },
        lualine_c = {
          -- path = 1 -> relative to cwd. The default (just the tail) is
          -- ambiguous the moment two buffers are both named init.lua, which in
          -- this config is most of the time.
          { 'filename', path = 1 },
        },
        lualine_x = { 'diagnostics', 'filetype' },
        -- 'progress' (percentage through the file) is dropped: the relative
        -- number column already answers "where am I", and options.lua pins it on.
        lualine_y = {},
        lualine_z = { 'location' },
      },
      -- oil buffers are directories, not files: the filename/diff/diagnostics
      -- components have nothing to say in them.
      extensions = { 'oil', 'lazy' },
    },
  },
}
