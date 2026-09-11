-- drills.lua — the drill catalogue. One entry per thing the fingers must learn.
--
-- Mirrors config/keymaps.lua and the plugin specs; when a bind changes there,
-- change it here. Fields:
--   keys     the literal keystrokes to type (termcode notation, <leader> ok)
--   prompt   what you're asked to do — phrased as intent, never as the key
--   cat      category, also the argument to :KeyDrill <cat>
--   note     shown on a miss: the *why*, so a mistake teaches something
--   optional true = kept out of the default mix (needs a terminal/multiplexer
--            feature that may not be there); still reachable via its category
--
-- Drills that end in a literal target char (jx, dj() are deliberate: find-char
-- is only muscle memory once the operand is part of the motion.
return {
  -- ─────────────────────────────────────────────────────────────── motion ──
  { cat = 'motion', keys = 'n', prompt = 'move left',  note = 'n e i o = ← ↓ ↑ →, home row under the right hand' },
  { cat = 'motion', keys = 'e', prompt = 'move down',  note = 'e = j' },
  { cat = 'motion', keys = 'i', prompt = 'move up',    note = 'i = k (normal/visual only — o-pending keeps `i` for text objects)' },
  { cat = 'motion', keys = 'o', prompt = 'move right', note = 'o = l' },

  { cat = 'motion', keys = 'N', prompt = 'move 5 left',  note = 'shift = ×5 step' },
  { cat = 'motion', keys = 'E', prompt = 'move 5 down',  note = 'shift = ×5 step' },
  { cat = 'motion', keys = 'I', prompt = 'move 5 up',    note = 'shift = ×5 step (not in visual — `I` there is block-insert)' },
  { cat = 'motion', keys = 'O', prompt = 'move 5 right', note = 'shift = ×5 step' },

  -- ─────────────────────────────────────────────────────────── line/word ──
  { cat = 'line', keys = 'q', prompt = 'jump to first non-blank of the line', note = 'q w f p = line-start · word-back · word-fwd · line-end' },
  { cat = 'line', keys = 'w', prompt = 'jump back one word',                  note = 'w = b' },
  { cat = 'line', keys = 'f', prompt = 'jump forward one word',               note = 'f = w' },
  { cat = 'line', keys = 'p', prompt = 'jump to last non-blank of the line',  note = 'p = g_ (not $ — stops on the last real character)' },

  { cat = 'line', keys = 'j(', prompt = "jump onto the next '('",   note = 'j = f (find, lands ON the char)' },
  { cat = 'line', keys = 'l,', prompt = "jump just before the next ','", note = 'l = t (till, stops BEFORE the char)' },
  { cat = 'line', keys = 'h',  prompt = 'jump to the matching bracket',  note = 'h = % (normal + operator-pending; visual `h` is reserved for treesitter expand)' },

  -- ─────────────────────────────────────────────────────────────── search ──
  { cat = 'search', keys = '!', prompt = 'start a forward search',  note = '! = / — mirrors tmux copy-mode' },
  { cat = 'search', keys = '?', prompt = 'start a backward search', note = '? keeps its vim default' },
  { cat = 'search', keys = 'k', prompt = 'go to the next match',    note = 'k = n' },
  { cat = 'search', keys = 'K', prompt = 'go to the previous match', note = 'K = N' },

  -- ───────────────────────────────────────────────────────────────── edit ──
  { cat = 'edit', keys = 'b',     prompt = 'undo',         note = 'b = u — a plain key, so it holds down to repeat' },
  { cat = 'edit', keys = '<C-r>', prompt = 'redo',         note = 'redo stays <C-r>' },
  { cat = 'edit', keys = 'u',     prompt = 'paste after the cursor',  note = 'u = p (tap-safe home row)' },
  { cat = 'edit', keys = 'U',     prompt = 'paste before the cursor', note = 'U = P' },
  { cat = 'edit', keys = '.',     prompt = 'repeat the last change',  note = '`.` stays default' },
  { cat = 'edit', keys = 'x',     prompt = 'delete the character under the cursor', note = 'x/X and r/R stay default' },

  -- ────────────────────────────────────────────────────────────── insert ──
  { cat = 'insert', keys = '<BS>',   prompt = 'enter insert mode here',      note = 'Backspace thumb = i' },
  { cat = 'insert', keys = 'Y',      prompt = 'insert at the line start',    note = 'Y = I' },
  { cat = 'insert', keys = 'a',      prompt = 'append after the cursor',     note = 'a/A stay default' },
  { cat = 'insert', keys = 'A',      prompt = 'append at the end of the line', note = 'a/A stay default' },
  { cat = 'insert', keys = '<CR>',   prompt = 'open a new line below',       note = 'Enter = o' },
  { cat = 'insert', keys = '<S-CR>', prompt = 'open a new line above',       note = 'Shift+Enter = O (needs the Kitty keyboard protocol)' },
  { cat = 'insert', keys = '<F13>',  prompt = 'get back to normal mode',     note = 'F13 — one key, from any mode, terminal included' },

  -- ──────────────────────────────────────────────────── operator compose ──
  -- The point of the layout: d/c/y are unchanged, so they compose with the new
  -- motions. These are the drills that make the whole thing pay off.
  { cat = 'compose', keys = 'de',  prompt = 'delete this line and the one below', note = 'operator + new motion: d + e(down)' },
  { cat = 'compose', keys = 'dp',  prompt = 'delete to the end of the line',      note = 'd + p(line end)' },
  { cat = 'compose', keys = 'dq',  prompt = 'delete back to the line start',      note = 'd + q(line start)' },
  { cat = 'compose', keys = 'd3e', prompt = 'delete 3 lines downward',            note = 'count goes between operator and motion' },
  { cat = 'compose', keys = 'cf',  prompt = 'change to the start of the next word', note = 'c + f(word forward)' },
  { cat = 'compose', keys = 'cw',  prompt = 'change back over the previous word',  note = 'c + w(word back)' },
  { cat = 'compose', keys = 'yp',  prompt = 'yank to the end of the line',         note = 'y + p(line end)' },
  { cat = 'compose', keys = 'yO',  prompt = 'yank the next 5 characters',          note = 'y + O(right ×5)' },
  { cat = 'compose', keys = 'dj;', prompt = "delete forward up to and including the next ';'", note = 'd + j(find) + the target char' },
  { cat = 'compose', keys = 'dl)', prompt = "delete forward up to but NOT including the next ')'", note = 'd + l(till) + the target char' },
  { cat = 'compose', keys = 'dh',  prompt = 'delete through to the matching bracket', note = 'd + h(%)' },
  { cat = 'compose', keys = 'ciw', prompt = 'change the word under the cursor',     note = 'text objects survive: o-pending leaves `i`/`a` alone' },
  { cat = 'compose', keys = 'di(', prompt = 'delete inside the parentheses',        note = 'use the operator form (di(), not vi( — visual `i` is up' },
  { cat = 'compose', keys = 'dap', prompt = 'delete a whole paragraph',             note = 'aw/ap/a( all still work' },
  { cat = 'compose', keys = 'va(', prompt = 'visually select a paren pair, brackets included', note = '`va(` still works in visual — it is `vi(` that is gone' },

  -- ──────────────────────────────────────────────────── buffers & finder ──
  { cat = 'buffers', keys = 'gt',    prompt = 'go to the next buffer',     note = 'gt / gT, like tabs' },
  { cat = 'buffers', keys = 'gT',    prompt = 'go to the previous buffer', note = 'gt / gT, like tabs' },
  { cat = 'buffers', keys = '<C-e>', prompt = 'fuzzy-find a file by name', note = 'Ctrl+E = fuzzy-jump at every layer (same as ^E in zsh); works from insert too' },
  { cat = 'buffers', keys = '<C-b>', prompt = 'fuzzy-switch to another open buffer', note = 'Ctrl+B — MRU sorted, so <C-b><CR> is the alternate-buffer toggle' },

  -- ────────────────────────────────────────────────────────────── leader ──
  { cat = 'leader', keys = '<leader>w',  prompt = 'write this file',       note = 'Space w (waits timeoutlen — `wa` shares the prefix)' },
  { cat = 'leader', keys = '<leader>wa', prompt = 'write every file',      note = 'Space w a' },
  { cat = 'leader', keys = '<leader>q',  prompt = 'quit the window',       note = 'Space q' },
  { cat = 'leader', keys = '<leader>e',  prompt = 'open the file explorer', note = 'Space e = oil, the directory as an editable buffer' },
  { cat = 'leader', keys = '<leader>gg', prompt = 'open lazygit',          note = 'Space g g — the <leader>g git tree' },

  -- ────────────────────────────────────────────────────────────── splits ──
  { cat = 'splits', keys = '<C-w>o', prompt = 'open a split to the right', note = '<C-w> + the direction key (n e i o)' },
  { cat = 'splits', keys = '<C-w>e', prompt = 'open a split below',        note = '<C-w> + the direction key (n e i o)' },
  { cat = 'splits', keys = '<C-w>n', prompt = 'open a split to the left',  note = '<C-w> + the direction key (n e i o)' },
  { cat = 'splits', keys = '<C-w>i', prompt = 'open a split above',        note = '<C-w> + the direction key (n e i o)' },

  -- ─────────────────────────────────────────────────────────────── panes ──
  -- Alt chords: under herdr these never reach nvim (see plugins/smart-splits.lua),
  -- so they stay out of the default mix — drill them with `:KeyDrill panes`.
  { cat = 'panes', optional = true, keys = '<M-n>', prompt = 'focus the split to the left',  note = 'Alt+neio = focus' },
  { cat = 'panes', optional = true, keys = '<M-e>', prompt = 'focus the split below',        note = 'Alt+neio = focus' },
  { cat = 'panes', optional = true, keys = '<M-i>', prompt = 'focus the split above',        note = 'Alt+neio = focus' },
  { cat = 'panes', optional = true, keys = '<M-o>', prompt = 'focus the split to the right', note = 'Alt+neio = focus' },
  { cat = 'panes', optional = true, keys = '<M-C-n>', prompt = 'grow/shrink the split leftward',  note = 'Alt+Ctrl+neio = resize (modifier escalation)' },
  { cat = 'panes', optional = true, keys = '<M-C-e>', prompt = 'grow/shrink the split downward',  note = 'Alt+Ctrl+neio = resize (modifier escalation)' },
  { cat = 'panes', optional = true, keys = '<M-C-i>', prompt = 'grow/shrink the split upward',    note = 'Alt+Ctrl+neio = resize (modifier escalation)' },
  { cat = 'panes', optional = true, keys = '<M-C-o>', prompt = 'grow/shrink the split rightward', note = 'Alt+Ctrl+neio = resize (modifier escalation)' },
}
