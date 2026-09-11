---@type vim.lsp.Config
return {
  cmd = { 'svelteserver', '--stdio' },
  filetypes = { 'svelte' },
  root_markers = {
    'package-lock.json',
    'yarn.lock',
    'pnpm-lock.yaml',
    'bun.lockb',
    'bun.lock',
    'deno.lock',
    '.git',
  },
}
