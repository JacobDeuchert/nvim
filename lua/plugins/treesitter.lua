-- nvim-treesitter — `main` branch (the rewrite). On nvim 0.11+ the old `master`
-- branch is frozen, and main has no `ensure_installed`/`highlight` options: you
-- call install() yourself and start highlighting per-buffer. Parser compilation
-- needs the tree-sitter CLI + a C compiler — both come from flake.nix.
--
-- Parsers for what actually gets edited on this VM (audako = C#/Angular, plus
-- the nix/lua config itself) — a superset of the host list. `install` is async
-- and a no-op when a parser is already present, so this is cheap on every start.
-- Add one: append here, then `:TSInstall <lang>` (or restart).
local parsers = {
  'angular', 'bash', 'c', 'c_sharp', 'css', 'csv', 'diff', 'dockerfile',
  'git_config', 'git_rebase', 'gitcommit', 'gitignore', 'go', 'html',
  'javascript', 'json', -- jsonc has no parser of its own; nvim maps the jsonc
  -- filetype onto the json one.
  'lua', 'luadoc', 'markdown', 'markdown_inline', 'nix', 'python', 'query',
  'regex', 'rust', 'scss', 'sql', 'svelte', 'toml', 'tsx', 'typescript', 'vim',
  'vimdoc', 'xml', 'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- Idempotent: install() skips parsers that are already built.
      require('nvim-treesitter').install(parsers)

      -- main doesn't wire highlighting up for us — do it per buffer, and only
      -- when a parser for that filetype actually exists (pcall keeps unknown
      -- filetypes from erroring on every open).
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
            return
          end
          -- Folds + indent off the same tree. indentexpr is opt-in per buffer
          -- because it's still the rougher edge of the rewrite.
          vim.wo[0][0].foldmethod = 'expr'
          vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
