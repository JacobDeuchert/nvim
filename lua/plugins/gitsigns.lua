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
    -- lazy only registers a stub command for a `cmd` trigger, so without this
    -- `:Gitsigns` does not exist until some buffer has fired the event above —
    -- i.e. it is missing in a bare `nvim` with no file argument.
    cmd = 'Gitsigns',
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

    -- :GsBase — review the current branch against another one.
    --
    -- gitsigns only ever diffs a buffer against a single revision, so a branch
    -- comparison is "stay on this branch, move the base". This wraps the three
    -- things that are easy to get wrong about doing that by hand:
    --
    --   • The base is set globally, so buffers opened afterwards inherit it.
    --     `:Gitsigns change_base main` without the global flag changes one buffer.
    --   • The base is the *merge base*, not the branch tip — "what did my branch
    --     change", rather than that plus everything main gained since the fork.
    --     `:GsBase!` uses the tip instead. `main...HEAD` cannot be passed through:
    --     the base is resolved with `git show <base>:<file>`, which rejects
    --     symmetric-difference syntax, and change_base swallows the failure.
    --   • The revision is verified first. change_base fails *silently* on an
    --     unknown rev: no error, previous base still in effect, stale signs.
    --
    -- Bare `:GsBase` goes back to diffing against the index. Follow up with
    -- `:Gitsigns setqflist all` for the files that aren't open yet.
    init = function()
      --- @return string? stdout, string? stderr
      local function git(cwd, ...)
        local res = vim.system({ 'git', ... }, { cwd = cwd, text = true }):wait()
        if res.code ~= 0 then
          return nil, vim.trim(res.stderr or '')
        end
        return vim.trim(res.stdout or '')
      end

      -- git has to run next to the file, not next to nvim's cwd: the two differ
      -- whenever a buffer is opened from outside the current working directory.
      local function buf_dir()
        local name = vim.api.nvim_buf_get_name(0)
        return name ~= '' and vim.fs.dirname(name) or assert(vim.uv.cwd())
      end

      vim.api.nvim_create_user_command('GsBase', function(cmd)
        local gs = require('gitsigns')

        if cmd.args == '' then
          gs.reset_base(true)
          vim.notify('gitsigns: base reset to index')
          return
        end

        local cwd = buf_dir()
        local rev = git(cwd, 'rev-parse', '--verify', '--quiet', cmd.args .. '^{commit}')
        if not rev then
          vim.notify('GsBase: no such revision: ' .. cmd.args, vim.log.levels.ERROR)
          return
        end

        local base = rev
        if not cmd.bang then
          base = git(cwd, 'merge-base', rev, 'HEAD') or rev
        end

        gs.change_base(base, true, function(err)
          vim.schedule(function()
            if err then
              vim.notify('GsBase: ' .. tostring(err), vim.log.levels.ERROR)
            else
              vim.notify(('gitsigns: base = %s (%s%s)'):format(cmd.args, base:sub(1, 8), cmd.bang and '' or ', merge base'))
            end
          end)
        end)
      end, {
        nargs = '?',
        bang = true,
        desc = 'gitsigns: diff every buffer against a branch (merge base; ! for its tip)',
        complete = function(arglead)
          local out = git(buf_dir(), 'for-each-ref', '--format=%(refname:short)', 'refs/heads', 'refs/remotes')
          if not out then
            return {}
          end
          return vim.tbl_filter(function(ref)
            return ref:find(arglead, 1, true) == 1
          end, vim.split(out, '\n', { trimempty = true }))
        end,
      })
    end,

    -- No keymaps yet: hunk navigation and stage/reset need a home in the
    -- <leader>g tree, which is still an open decision alongside which-key.
    -- Everything is reachable meanwhile via `:Gitsigns <action>`.
  },
}
