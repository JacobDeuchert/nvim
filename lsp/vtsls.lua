-- lsp/vtsls.lua — TypeScript/JavaScript. nvim 0.12 reads this file by name when
-- something calls vim.lsp.enable('vtsls') (config/servers.lua), so there is no
-- plugin and no nvim-lspconfig involved: the whole server definition is here.
--
-- vtsls, not typescript-language-server: both wrap the same tsserver, but vtsls
-- exposes the editor-side commands tsserver has and LSP does not — organize
-- imports, "move to file", update-imports-on-rename — through plain
-- workspace/executeCommand, so `ga` (code action, config/lsp.lua) offers the
-- same fixes VS Code does. ts_ls drops most of them.
--
-- The binary comes from the Home Manager module in flake.nix; do NOT let mason
-- or `npm -g` install a
-- second copy (same rule as roslyn-ls in plugins/roslyn.lua).
--
-- Keymaps are not here — they attach on LspAttach for every server
-- (config/lsp.lua). Inlay hints are requested below but stay hidden until the
-- per-buffer <leader>li toggle.
local inlay_hints = {
  -- `literals` only: naming every argument turns a call like foo(a, b, c) into
  -- noise, but a bare `true`/`0`/`'x'` at a call site is the case where the
  -- parameter name is genuinely missing information.
  parameterNames = { enabled = 'literals' },
  parameterTypes = { enabled = true },
  -- Off: TS infers nearly every local, so this shifts most lines in the file.
  variableTypes = { enabled = false },
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  enumMemberValues = { enabled = true },
}

return {
  cmd = { 'vtsls', '--stdio' },
  filetypes = {
    'javascript', 'javascriptreact', 'javascript.jsx',
    'typescript', 'typescriptreact', 'typescript.tsx',
  },
  -- tsconfig/jsconfig first so a monorepo attaches per package instead of one
  -- server for the whole tree; .git last as the fallback for loose scripts.
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  settings = {
    vtsls = {
      -- Use the repo's own typescript from node_modules when it has one — the
      -- alternative is diagnostics from whatever version nixpkgs pinned, which
      -- disagrees with what `tsc` in CI says.
      autoUseWorkspaceTsdk = true,
      experimental = {
        completion = { enableServerSideFuzzyMatch = true },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = 'always' },
      inlayHints = inlay_hints,
      -- Angular repos (audako) are deep; a relative import chain of ../../.. is
      -- worse than the path alias tsconfig already defines.
      preferences = { importModuleSpecifier = 'shortest' },
      -- tsserver's default heap is ~3 GB and an Angular app plus its .d.ts set
      -- can walk into it; the VM has room.
      tsserver = { maxTsServerMemory = 4096 },
    },
    javascript = {
      updateImportsOnFileMove = { enabled = 'always' },
      inlayHints = inlay_hints,
    },
  },
}
