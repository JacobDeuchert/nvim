-- lsp.lua — the LSP binding scheme. Server-agnostic on purpose: roslyn is the
-- first server (plugins/roslyn.lua), TS/rust/nix will follow and must not each
-- re-declare the layout. Everything here hangs off one LspAttach autocmd, so a
-- new server inherits the whole scheme by existing.
--
-- Two rules carried over from config/keymaps.lua:
--   • next/prev is k / K (search does it; diagnostics do it the same way).
--   • what's-under-the-cursor is `g` + a mnemonic, never a home-row letter —
--     n/e/i/o are motions and stay motions.
--
-- Multi-result actions (references, implementations, symbols) open telescope
-- rather than the quickfix list: the picker is already the answer to "which of
-- these did I mean" everywhere else in this config (plugins/telescope.lua).

-- ────────────────────────────────────── Drop neovim's built-in LSP binds ──
-- 0.11+ ships grn/gra/grr/gri/grt/gO as global normal-mode maps. They are
-- deleted, not shadowed, because this config wants a bare `gr` — with the
-- defaults in place every `gr` would sit and wait `timeoutlen` for a possible
-- `grn`/`gra`/…, which is exactly the pause <leader>w already pays for and one
-- is enough. Cost: LSP binds here no longer match a stock neovim elsewhere.
-- i_CTRL-S (signature help in insert) is deliberately left alone — insert mode
-- can't reach `g` binds, so it's the only signature help available while typing.
for _, lhs in ipairs({ 'grn', 'gra', 'grr', 'gri', 'grt', 'gO' }) do
  for _, mode in ipairs({ 'n', 'x' }) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

-- Telescope's LSP pickers, loaded on demand (lazy.nvim resolves the require).
-- stopinsert mirrors plugins/telescope.lua: closing a picker shouldn't drop back
-- into a half-abandoned insert.
local function picker(name, args)
  return function()
    vim.cmd('stopinsert')
    require('telescope.builtin')[name](args)
  end
end

local function bind(bufnr)
  local function def(modes, lhs, rhs, desc)
    vim.keymap.set(modes, lhs, rhs, { buffer = bufnr, desc = 'lsp: ' .. desc, silent = true })
  end

  -- ───────────────────────────────────────────────────────────── Inspect ──
  -- Hover has no home key left: K is prev-match in this layout, so it moves to
  -- `gh` — `h` already means "what is this / match" in normal+op-pending.
  -- Shadows the select-mode entry points (gh/gH), which this config never uses.
  def({ 'n' }, 'gh', vim.lsp.buf.hover,          'hover')
  def({ 'n' }, 'gH', vim.lsp.buf.signature_help, 'signature help')

  -- ────────────────────────────────────────────────────────── Navigation ──
  -- Single-result jumps go straight there; the rest open a picker.
  -- `gi` costs vim's "insert at last insert position" and `gy` was free.
  def({ 'n' }, 'gd', picker('lsp_definitions'),      'definitions')
  def({ 'n' }, 'gD', vim.lsp.buf.declaration,        'declaration')
  def({ 'n' }, 'gr', picker('lsp_references'),       'references')
  def({ 'n' }, 'gi', picker('lsp_implementations'),  'implementations')
  def({ 'n' }, 'gy', picker('lsp_type_definitions'), 'type definition')

  -- ───────────────────────────────────────────────────────── Diagnostics ──
  -- Same verb as search: k = next, K = prev (keymaps.lua). Cost: `gk` was
  -- display-line-up — with the n/e/i/o motion layer, display-line movement was
  -- never going to live on j/k anyway, so nothing coherent is lost.
  def({ 'n' }, 'gk', function() vim.diagnostic.jump({ count = 1, float = true }) end,  'next diagnostic')
  def({ 'n' }, 'gK', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'prev diagnostic')

  -- ─────────────────────────────────────────────────────────── Code action ──
  -- Top-level `ga` (was :ascii) rather than only <leader>la: C# fires this
  -- constantly — add using, implement interface, fix — and <leader>l* pays the
  -- prefix pause. Visual mode included for range actions (extract method).
  def({ 'n', 'x' }, 'ga', vim.lsp.buf.code_action, 'code action')

  -- ──────────────────────────────────────────────── <leader>l · the rest ──
  -- Everything that is deliberate, rare, or destructive. Rename lives here and
  -- not on a bare key on purpose: it edits every call site at once.
  def({ 'n' }, '<leader>lr', vim.lsp.buf.rename,                            'rename')
  def({ 'n' }, '<leader>la', vim.lsp.buf.code_action,                       'code action')
  def({ 'n' }, '<leader>lf', function() vim.lsp.buf.format({ async = true }) end, 'format')
  def({ 'n' }, '<leader>ld', picker('diagnostics', { bufnr = 0 }),          'diagnostics (buffer)')
  def({ 'n' }, '<leader>lD', picker('diagnostics'),                         'diagnostics (all)')
  def({ 'n' }, '<leader>ls', picker('lsp_document_symbols'),                'document symbols')
  def({ 'n' }, '<leader>lS', picker('lsp_dynamic_workspace_symbols'),       'workspace symbols')

  -- Inlay hints start off (they shift the whole line); this toggles per buffer.
  -- Nothing shows unless the server is told to send them — see the
  -- csharp|inlay_hints block in plugins/roslyn.lua.
  def({ 'n' }, '<leader>li', function()
    local filter = { bufnr = 0 }
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
  end, 'toggle inlay hints')

  -- Restart: core has no :LspRestart (that was lspconfig's). Stop every client
  -- on this buffer and re-edit — the FileType autocmd re-attaches from scratch,
  -- which is the actual fix when roslyn loses the solution.
  def({ 'n' }, '<leader>lR', function()
    local file = vim.api.nvim_buf_get_name(0)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      client:stop(true)
    end
    vim.defer_fn(function() vim.cmd('edit ' .. vim.fn.fnameescape(file)) end, 500)
  end, 'restart server')
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('config.lsp', { clear = true }),
  callback = function(ev)
    bind(ev.buf)
  end,
})

-- Diagnostics display. `virtual_text` stays off: on a C# solution with full
-- background analysis it turns every line into a wall of end-of-line text.
-- `virtual_lines` scoped to the cursor line replaces it — the full message,
-- wrapped, below the line you are actually on and nowhere else. That keeps the
-- wall away while making an error impossible to miss, which plain underline +
-- sign was not: undercurl is a two-pixel cue and the signs below were empty
-- strings, so a hard CS error rendered as nothing at all.
vim.diagnostic.config({
  severity_sort = true,
  virtual_text = false,
  virtual_lines = { current_line = true },
  underline = true,
  float = { border = 'rounded', source = true },
  -- Distinct shapes, not four dots in four colours: severity has to survive a
  -- glance at the gutter without a colour-to-meaning lookup.
  --
  -- Written as \u{} escapes, NOT as literal glyphs. These are Private Use Area
  -- codepoints, and this exact list already silently lost its contents once —
  -- something in the write path (editor, copy, agent tooling) dropped the PUA
  -- bytes and left four empty strings, which draws nothing and made a hard CS
  -- error invisible. Escapes are plain ASCII on disk, so they cannot be eaten.
  --
  -- They resolve against the terminal font, pinned to FiraCode Nerd Font in
  -- nixos-work home.nix (programs.alacritty). If these render as boxes, check
  -- that font before touching this list.
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '\u{f057}', -- nf-fa-times_circle
      [vim.diagnostic.severity.WARN]  = '\u{f071}', -- nf-fa-warning
      [vim.diagnostic.severity.INFO]  = '\u{f05a}', -- nf-fa-info_circle
      [vim.diagnostic.severity.HINT]  = '\u{f059}', -- nf-fa-question_circle
    },
  },
})
