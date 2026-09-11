-- keymaps.lua — the hand-written binding scheme (the deliverable).
-- Source of intent: 04-neovim.md. Pure Lua; plugin binds live in plugin specs.
--
-- Mode lists (vim.keymap.set is noremap by default, so rhs uses builtins):
--   NXO = normal + visual + operator-pending   NX = normal + visual   NO = normal + op-pending
local NXO = { 'n', 'x', 'o' }
local NX  = { 'n', 'x' }
local NO  = { 'n', 'o' }

local function def(modes, lhs, rhs, desc)
  vim.keymap.set(modes, lhs, rhs, { desc = desc, silent = true })
end

-- ─────────────────────────────────────────────────────────────── Motion ──
-- N E I O = ← ↓ ↑ →. Operator-pending included so d/c/y compose (dn, c3e, yo…).
-- `i` (up) is normal+visual only: operator-pending leaves `i`/`a` as text-object
-- prefixes, so diw / ci( / dap work.
--   Tradeoff (accepted): in VISUAL, `i` shadows inner text-objects (no `vi(`).
--   Use the operator form (di(, ci() — this layout's primary path; `va(` still works.
def(NXO, 'n', 'h', 'left')
def(NXO, 'e', 'j', 'down')
def(NXO, 'o', 'l', 'right')
def(NX,  'i', 'k', 'up')              -- not o-mode (keep `i` for text objects)

-- ×5 fast step. N/E/O everywhere; `I` skips VISUAL so visual-block `I` (block
-- insert) survives — use a count (5i) for ×5-up inside a visual selection.
def(NXO, 'N', '5h', 'left ×5')
def(NXO, 'E', '5j', 'down ×5')
def(NXO, 'O', '5l', 'right ×5')
def(NO,  'I', '5k', 'up ×5')

-- Line / word cluster: q w f p = line-start · word-back · word-fwd · line-end.
def(NXO, 'q', '^',  'line start')
def(NXO, 'w', 'b',  'word back')
def(NXO, 'f', 'w',  'word forward')
def(NXO, 'p', 'g_', 'line end')

-- find-char: j = onto (f), l = till (t). Backward find-char → flash (plugin, TODO).
def(NXO, 'j', 'f', 'find char →')
def(NXO, 'l', 't', 'till char →')

-- matching bracket. Normal + op-pending only; VISUAL `h` is reserved for the
-- treesitter incremental-expand plugin (TODO).
def(NO, 'h', '%', 'match bracket')

-- search: ! = forward · ? = backward (native, unmapped) · k / K = next / prev
-- match. Mirrors tmux copy-mode (03-tmux.md). `?` keeps its vim default.
def(NXO, '!', '/', 'search →')
def(NXO, 'k', 'n', 'next match')
def(NXO, 'K', 'N', 'prev match')

-- ──────────────────────────────────────────────────────────── Operators ──
-- d c y stay default operators and compose with the motions above.
-- Swaps: b = undo (plain key → holdable to repeat), u/U = paste (tap-safe).
def({ 'n' }, 'b', 'u', 'undo')
def(NX,      'u', 'p', 'paste after')   -- visual: paste over selection
def(NX,      'U', 'P', 'paste before')  -- visual: paste w/o clobbering the register
-- Native black-hole deletion is `"_d`; make the useful prefix directly available.
def(NX,      '_d', '"_d', 'delete without copying')
-- redo stays <C-r>; repeat stays `.`; x/X r/R and the c-family stay default.

-- ──────────────────────────────────────────────────────── Insert / entry ──
def({ 'n' }, '<BS>',   'i', 'insert')                -- Backspace thumb = insert
def({ 'n' }, 'Y',      'I', 'insert @ line start')
def({ 'n' }, '<CR>',   'o', 'open line below')
def({ 'n' }, '<S-CR>', 'O', 'open line above')       -- needs Kitty protocol (Alacritty ✓)
-- a/A append stay default.

-- ─────────────────────────────────────────────────────── Escape → normal ──
-- F13 = "get me to normal mode", from wherever I am. A dedicated keycode no
-- layer above claims, so it can't be confused with a real Esc or an Alt chord
-- (Esc is the lead byte of every escape sequence — F13 has no such ambiguity,
-- which also means no escape-time guessing in tmux).
-- Terminal mode included: this is the pair agent's exit hatch (05-agents.md),
-- replacing the <C-\><C-n> default.
--
-- Bound under two names on purpose. The keysym is F13 (after the
-- fkeys:basic_13-24 xkb option — without it the compositor turns the key into
-- XF86Tools and nothing arrives at all), but the terminal encodes F13-F24 as
-- *shifted* F-keys, so nvim decodes the escape sequence back as <S-F3>. Both
-- names are the same physical key; Shift+F3 isn't otherwise reachable on the
-- Voyager, so claiming it costs nothing.
for _, key in ipairs({ '<F13>', '<S-F3>' }) do
  def({ 'i', 'x', 's', 'o', 'c' }, key, '<Esc>', 'normal mode')
  def({ 't' }, key, [[<C-\><C-n>]], 'normal mode (terminal)')
  -- In normal mode, keep Esc's usual "cancel pending count/operator" meaning.
  def({ 'n' }, key, '<Esc>', 'cancel pending')
end

-- Keep <CR> meaning "select/confirm" in list-like buffers (quickfix, help, …).
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'qf', 'help', 'man', 'lspinfo', 'checkhealth' },
  callback = function(ev)
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = ev.buf, silent = true })
  end,
})

-- ────────────────────────────────────────────────────────────── Buffers ──
def({ 'n' }, 'gt', '<cmd>bnext<cr>',     'next buffer')
def({ 'n' }, 'gT', '<cmd>bprevious<cr>', 'prev buffer')

-- ─────────────────────────────────────────────────────── <leader> · file ──
-- Note: `wa` makes `w` a prefix, so a plain <leader>w waits `timeoutlen`
-- (see options.lua) before firing — that pause is the price of keeping both
-- under the same letter.
def({ 'n' }, '<leader>w',  '<cmd>write<cr>', 'write')
def({ 'n' }, '<leader>wa', '<cmd>wall<cr>',  'write all')
def({ 'n' }, '<leader>q',  '<cmd>quit<cr>',  'quit')

-- ─────────────────────────────────────────────────────────────── Splits ──
-- Directional, matching tmux (o/e/n/i = right/down/left/up). Prefix = <C-w>
-- (Alt+Space belongs to tmux). Overrides <C-w> only/new/decl — rebind "only"
-- onto <leader> later if you miss it.
def({ 'n' }, '<C-w>o', '<cmd>belowright vsplit<cr>', 'split right')
def({ 'n' }, '<C-w>e', '<cmd>belowright split<cr>',  'split down')
def({ 'n' }, '<C-w>n', '<cmd>aboveleft vsplit<cr>',  'split left')
def({ 'n' }, '<C-w>i', '<cmd>aboveleft split<cr>',   'split up')

-- ─────────────────────────────────────── Deferred → plugin specs (TODO) ──
--   Alt+neio focus / Alt+Ctrl+neio resize   ✅ smart-splits.nvim (plugins/smart-splits.lua)
--   gh hover · gd/gr/gi/gy · gk/gK · ga    ✅ LSP, on LspAttach (config/lsp.lua)
--   s / S = flash jump / treesitter-select  → flash.nvim
--   visual `h` = incremental expand         → nvim-treesitter
--   <leader> tree (find/git/buffers/agent)  → which-key + finder
