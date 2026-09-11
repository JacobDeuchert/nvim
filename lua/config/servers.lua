-- servers.lua — which language servers are on. One line per server; the actual
-- definition lives in ../../lsp/<name>.lua, which nvim 0.12 loads by name off
-- the runtimepath. Servers that come with a plugin are NOT listed here (roslyn
-- is enabled by roslyn.nvim itself — plugins/roslyn.lua).
--
-- Separate from config/lsp.lua on purpose: that file is the server-agnostic
-- binding scheme and stays that way. This is the roster.
vim.lsp.enable({
  'svelte',
  'vtsls', -- TypeScript/JavaScript
})
