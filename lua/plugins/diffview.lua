-- diffview.nvim — the PR-review view: every file a branch touched, in one panel,
-- with each one's diff a keystroke away.
--
-- This is the third leg of the git tree, and the three do not overlap:
--   lazygit (<leader>gg)  — stage, commit, rebase: change the repo.
--   gitsigns (passive)    — what did I change on *this line*, in the buffer I'm in.
--   diffview (<leader>gd) — read a whole changeset: the file list is the agenda,
--                           and you walk it top to bottom until it's empty.
--
-- :Review is the entry point, because "review this branch" is not a diff against
-- the branch you'd name — it's a diff against the *merge base*, i.e. what this
-- branch did, not that plus everything main gained since the fork. Same
-- distinction :GsBase draws (plugins/gitsigns.lua); the two are deliberately
-- symmetric, and `!` means the same thing in both (branch tip, not merge base).
return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewToggleFiles',
      'DiffviewFocusFiles',
      'DiffviewFileHistory',
      'DiffviewRefresh',
    },
    keys = {
      { '<leader>gd', '<cmd>Review<cr>',            desc = 'review branch vs merge base (diffview)' },
      { '<leader>gc', '<cmd>DiffviewOpen<cr>',      desc = 'diff uncommitted changes' },
      { '<leader>gx', '<cmd>DiffviewClose<cr>',     desc = 'close diffview' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'history of this file' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<cr>',   desc = 'history of this branch' },
    },

    -- :Review [rev] — open the changeset of the current branch against `rev`
    -- (default: the remote's default branch, else main/master).
    --
    -- Registered in `init` so the command and its branch completion exist in a
    -- bare `nvim`, before diffview itself has been loaded — `DiffviewOpen` below
    -- is lazy's stub, so calling it is what pulls the plugin in.
    init = function()
      local function git(...)
        local res = vim.system({ 'git', ... }, { cwd = assert(vim.uv.cwd()), text = true }):wait()
        return res.code == 0 and vim.trim(res.stdout or '') or nil
      end

      -- Priority: next, then master, then main (remote first for each).
      -- `origin/HEAD` only as a last resort — it's present only if the clone
      -- recorded it (`git remote set-head origin -a` fixes a clone that didn't)
      -- and it usually just points at main anyway.
      local function default_base()
        for _, name in ipairs({
          'origin/next', 'next',
          'origin/master', 'master',
          'origin/main', 'main',
        }) do
          if git('rev-parse', '--verify', '--quiet', name .. '^{commit}') then
            return name
          end
        end
        return git('symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
      end

      vim.api.nvim_create_user_command('Review', function(cmd)
        local base = cmd.args ~= '' and cmd.args or default_base()
        if not base then
          vim.notify('Review: no default branch found — pass one (:Review <rev>)', vim.log.levels.ERROR)
          return
        end
        if not git('rev-parse', '--verify', '--quiet', base .. '^{commit}') then
          vim.notify('Review: no such revision: ' .. base, vim.log.levels.ERROR)
          return
        end

        -- `a...b` is the merge-base diff, `a..b` the plain one. --imply-local puts
        -- the *working-tree* file in the right-hand window instead of a read-only
        -- copy of HEAD, so a typo you spot while reading is fixable on the spot.
        local range = cmd.bang and '..' or '...'
        vim.cmd(('DiffviewOpen %s%sHEAD --imply-local'):format(base, range))
      end, {
        nargs = '?',
        bang = true,
        desc = 'diffview: review this branch against a base (merge base; ! for its tip)',
        complete = function(arglead)
          local out = git('for-each-ref', '--format=%(refname:short)', 'refs/heads', 'refs/remotes')
          if not out then
            return {}
          end
          return vim.tbl_filter(function(ref)
            return ref:find(arglead, 1, true) == 1
          end, vim.split(out, '\n', { trimempty = true }))
        end,
      })
    end,

    -- opts as a function so requiring diffview.actions doesn't load the plugin
    -- at startup (same reason as telescope.lua).
    opts = function()
      local actions = require('diffview.actions')

      return {
        enhanced_diff_hl = true,
        view = {
          -- Side-by-side, old on the left. diff3_mixed for conflicts: both sides
          -- on top, the working (conflicted) file underneath, which is the one
          -- you actually edit.
          default = { layout = 'diff2_horizontal', winbar_info = true },
          merge_tool = { layout = 'diff3_mixed', disable_diagnostics = true, winbar_info = true },
          file_history = { layout = 'diff2_horizontal', winbar_info = true },
        },
        file_panel = {
          listing_style = 'tree',
          tree_options = { flatten_dirs = true, folder_statuses = 'only_folded' },
          win_config = { position = 'left', width = 40 },
        },

        -- Defaults kept, except where they'd shadow the motion layer. diffview's
        -- panels are buffer-local maps, so anything it claims wins over
        -- config/keymaps.lua inside them — and a file list is exactly where you
        -- reach for n/e/i/o without thinking. `false` removes a default.
        keymaps = {
          view = {
            -- Walking the changeset without going back to the panel: this is the
            -- "next file" key, and the reason the panel can stay closed.
            { 'n', '<tab>',     actions.select_next_entry, { desc = 'next file in the changeset' } },
            { 'n', '<s-tab>',   actions.select_prev_entry, { desc = 'prev file in the changeset' } },
            -- Panel focus/toggle move out of <leader>e (oil) and into the git tree.
            { 'n', '<leader>e', false },
            { 'n', '<leader>b', false },
            { 'n', '<leader>gf', actions.focus_files,  { desc = 'focus the file panel' } },
            { 'n', '<leader>gb', actions.toggle_files, { desc = 'toggle the file panel' } },
          },
          file_panel = {
            -- j/k → e/i. Entry-wise, not line-wise: in tree view a line can be a
            -- folder, and these skip to the next actual file.
            { 'n', 'j', false },
            { 'n', 'k', false },
            { 'n', 'e', actions.next_entry, { desc = 'next file' } },
            { 'n', 'i', actions.prev_entry, { desc = 'prev file' } },
            -- Keep the motion/find layer intact. <cr> opens an entry and zc closes
            -- a fold, so diffview's l/h aliases are redundant.
            { 'n', 'o', false },
            { 'n', 'l', false },
            { 'n', 'h', false },
            -- The two view-shape toggles move off i/f (up / word-forward) onto t/T.
            { 'n', 'f', false },
            { 'n', 't', actions.listing_style,      { desc = "toggle 'list' / 'tree' view" } },
            { 'n', 'T', actions.toggle_flatten_dirs, { desc = 'toggle flattened directories' } },
            { 'n', '<leader>e', false },
            { 'n', '<leader>b', false },
            { 'n', '<leader>gf', actions.focus_files,  { desc = 'focus the file panel' } },
            { 'n', '<leader>gb', actions.toggle_files, { desc = 'toggle the file panel' } },
          },
          file_history_panel = {
            { 'n', 'j', false },
            { 'n', 'k', false },
            { 'n', 'e', actions.next_entry, { desc = 'next commit' } },
            { 'n', 'i', actions.prev_entry, { desc = 'prev commit' } },
            { 'n', 'o', false },
            { 'n', 'l', false },
            { 'n', 'h', false },
            { 'n', '<leader>e', false },
            { 'n', '<leader>b', false },
            { 'n', '<leader>gf', actions.focus_files,  { desc = 'focus the file panel' } },
            { 'n', '<leader>gb', actions.toggle_files, { desc = 'toggle the file panel' } },
          },
        },
      }
    end,
  },
}
