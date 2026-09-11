local M = {}

function M.yank(first, last)
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' or vim.bo.buftype ~= '' then
    vim.notify('Agent reference requires a file buffer', vim.log.levels.WARN)
    return
  end

  local root = vim.fs.root(0, '.git')
    or vim.fs.root(0, { 'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'flake.nix' })
    or vim.fn.getcwd()
  path = vim.fs.relpath(root, path) or path

  first, last = math.min(first, last), math.max(first, last)
  local reference = string.format('%s:%d-%d', path, first, last)
  vim.fn.setreg('+', reference, 'v')
  vim.notify('Copied ' .. reference)
end

function M.setup()
  vim.api.nvim_create_user_command('AgentRef', function(opts)
    M.yank(opts.line1, opts.line2)
  end, { range = true, desc = 'Copy file and line range for an agent' })

  vim.keymap.set('n', '<leader>ay', '<cmd>AgentRef<cr>', {
    desc = 'Yank agent reference', silent = true,
  })
  -- Leaving Visual mode via : supplies the selected line range to the command.
  vim.keymap.set('x', '<leader>ay', ':AgentRef<cr>', {
    desc = 'Yank agent reference', silent = true,
  })
end

return M
