// Curated Neovim command catalogue for this repository.
// Owned by the web app: update manually when lua/config/keymaps.lua,
// lua/config/lsp.lua or the plugin specs change.
//
// Scope (per webapp-plan.md):
// - only mappings implemented in the checked-in config, plus important
//   intentionally-retained defaults (marked [default] in why/desc).
// - plugin-interface-internal controls (Telescope prompt keys, lazygit
//   keybinds) are excluded; their entry points (<C-e>, <leader>gg, ...) stay.
// - planned/TODO binds (flash, treesitter expand, <leader> tree) excluded.

import {
  ALT_KEYS,
  BKSP_ID,
  CTRL_KEYS,
  ENTER_ID,
  EXLM_SLOT_ID,
  HOLD_F_ID,
  LETTER_KEY,
  QST_SLOT_ID,
  SHIFT_KEYS,
  SPACE_ID,
  UNDERSCORE_SLOT_ID,
} from './layout';

export type Mode = 'n' | 'x' | 'o' | 'i' | 't' | 'c';
export type Category =
  | 'Movement'
  | 'Search'
  | 'Editing'
  | 'Mode Entry'
  | 'Files/Buffers'
  | 'Windows/Panes'
  | 'LSP'
  | 'Git';

export interface Command {
  seq: string;
  label: string; // short keycap-center label
  desc: string;
  modes: Mode[];
  cat: Category;
  why: string; // ergonomic / mnemonic rationale
  keys: string[]; // physical key ids involved (incl. alternative modifiers)
}

export const MODES: { id: Mode; name: string }[] = [
  { id: 'n', name: 'Normal' },
  { id: 'x', name: 'Visual' },
  { id: 'o', name: 'Operator-pending' },
  { id: 'i', name: 'Insert' },
  { id: 't', name: 'Terminal' },
  { id: 'c', name: 'Command-line' },
];

export const CATEGORIES: Category[] = [
  'Movement',
  'Search',
  'Editing',
  'Mode Entry',
  'Files/Buffers',
  'Windows/Panes',
  'LSP',
  'Git',
];

const L = (ch: string): string => LETTER_KEY[ch.toUpperCase()];
const SH = [...SHIFT_KEYS];
const CT = [...CTRL_KEYS];
const AL = [...ALT_KEYS];
const NXO: Mode[] = ['n', 'x', 'o'];
const NX: Mode[] = ['n', 'x'];
const ALL_MODES: Mode[] = ['n', 'x', 'o', 'i', 't', 'c'];

export const COMMANDS: Command[] = [
  // ── Movement ──
  { seq: 'n', label: '←', desc: 'Move left', modes: NXO, cat: 'Movement', why: 'Home row arrows: n e i o = ← ↓ ↑ → under the right hand.', keys: [L('n')] },
  { seq: 'e', label: '↓', desc: 'Move down', modes: NXO, cat: 'Movement', why: 'Home row arrows; e replaces j so operators compose (de, ce).', keys: [L('e')] },
  { seq: 'i', label: '↑', desc: 'Move up', modes: ['n', 'x'], cat: 'Movement', why: 'Home row arrows. Operator-pending keeps i for text objects, so diw and ci( survive.', keys: [L('i')] },
  { seq: 'o', label: '→', desc: 'Move right', modes: NXO, cat: 'Movement', why: 'Home row arrows; o replaces l.', keys: [L('o')] },
  { seq: 'N', label: '×5 ←', desc: 'Move 5 left', modes: NXO, cat: 'Movement', why: 'Shift = ×5 fast step, mirroring the ×5 counts without typing a digit.', keys: [L('n'), ...SH] },
  { seq: 'E', label: '×5 ↓', desc: 'Move 5 down', modes: NXO, cat: 'Movement', why: 'Shift = ×5 fast step for coasting through files.', keys: [L('e'), ...SH] },
  { seq: 'I', label: '×5 ↑', desc: 'Move 5 up', modes: ['n', 'o'], cat: 'Movement', why: 'Shift = ×5. Skips Visual so block-insert I survives; use a count (5i) there.', keys: [L('i'), ...SH] },
  { seq: 'O', label: '×5 →', desc: 'Move 5 right', modes: NXO, cat: 'Movement', why: 'Shift = ×5 fast step.', keys: [L('o'), ...SH] },
  { seq: 'q', label: '⌞ line', desc: 'Jump to first non-blank of the line (^)', modes: NXO, cat: 'Movement', why: 'Line/word cluster q w f p sits together: line-start · word-back · word-fwd · line-end.', keys: [L('q')] },
  { seq: 'w', label: '‹word', desc: 'Jump back one word (b)', modes: NXO, cat: 'Movement', why: 'Line/word cluster; w replaces b.', keys: [L('w')] },
  { seq: 'f', label: 'word›', desc: 'Jump forward one word (w)', modes: NXO, cat: 'Movement', why: 'Line/word cluster; f replaces w.', keys: [L('f')] },
  { seq: 'p', label: 'line ⌟', desc: 'Jump to last non-blank of the line (g_)', modes: NXO, cat: 'Movement', why: 'Line/word cluster; stops on the last real character, unlike $.', keys: [L('p')] },
  { seq: 'j{char}', label: 'find↠', desc: 'Jump onto the next {char} (f)', modes: NXO, cat: 'Movement', why: 'j = find, lands ON the char. Composes: dj; deletes through the next semicolon.', keys: [L('j')] },
  { seq: 'l{char}', label: 'till↠', desc: 'Jump just before the next {char} (t)', modes: NXO, cat: 'Movement', why: 'l = till, stops BEFORE the char. Backward find-char is a future flash bind.', keys: [L('l')] },
  { seq: 'h', label: '% {}', desc: 'Jump to the matching bracket (%)', modes: ['n', 'o'], cat: 'Movement', why: 'h already means "what is this / match". Visual h is reserved for treesitter expand (planned).', keys: [L('h')] },

  // ── Search ──
  { seq: '!', label: 'search', desc: 'Start a forward search (/)', modes: NXO, cat: 'Search', why: '! replaces / and mirrors the tmux copy-mode search key.', keys: [HOLD_F_ID, EXLM_SLOT_ID] },
  { seq: '?', label: '? back', desc: 'Start a backward search [default]', modes: NXO, cat: 'Search', why: 'Kept the vim default; forward search moved to !.', keys: [HOLD_F_ID, QST_SLOT_ID] },
  { seq: 'k', label: 'next ✓', desc: 'Go to the next match (n)', modes: NXO, cat: 'Search', why: 'Next/prev is k / K everywhere: search matches and diagnostics share the verb.', keys: [L('k')] },
  { seq: 'K', label: 'prev ✓', desc: 'Go to the previous match (N)', modes: NXO, cat: 'Search', why: 'Same verb as diagnostics (gk / gK); K was freed by moving hover to gh.', keys: [L('k'), ...SH] },

  // ── Editing ──
  { seq: 'b', label: 'undo', desc: 'Undo (u)', modes: ['n'], cat: 'Editing', why: 'Swapped onto a plain home key so it holds down to repeat.', keys: [L('b')] },
  { seq: 'u', label: 'paste+', desc: 'Paste after the cursor (p)', modes: NX, cat: 'Editing', why: 'Tap-safe home-row paste; visual mode pastes over the selection.', keys: [L('u')] },
  { seq: 'U', label: '+paste', desc: 'Paste before the cursor (P)', modes: NX, cat: 'Editing', why: 'Tap-safe home-row paste without clobbering the register in visual.', keys: [L('u'), ...SH] },
  { seq: '_d', label: 'del∅', desc: 'Delete without copying ("_d)', modes: NX, cat: 'Editing', why: 'The useful black-hole prefix made directly available; _ is hold-F plus the _ slot.', keys: [HOLD_F_ID, UNDERSCORE_SLOT_ID, L('d')] },
  { seq: 'd', label: 'delete', desc: 'Delete operator [default]', modes: NX, cat: 'Editing', why: 'Unchanged so it composes with the new motions: de, dp, dq, dh.', keys: [L('d')] },
  { seq: 'c', label: 'change', desc: 'Change operator [default]', modes: NX, cat: 'Editing', why: 'Unchanged; composes with the new motions: cf, cw, ciw.', keys: [L('c')] },
  { seq: 'y', label: 'yank', desc: 'Yank operator [default]', modes: NX, cat: 'Editing', why: 'Unchanged; composes with the new motions: yp, yO.', keys: [L('y')] },
  { seq: 'x', label: 'del ch', desc: 'Delete the character under the cursor [default]', modes: NX, cat: 'Editing', why: 'Kept default, with X, r and R. The c-family also stays default.', keys: [L('x')] },
  { seq: '<C-r>', label: 'redo', desc: 'Redo [default]', modes: ['n'], cat: 'Editing', why: 'Redo stays <C-r>; repeat stays ..', keys: [L('r'), ...CT] },
  { seq: '.', label: 'repeat', desc: 'Repeat the last change [default]', modes: ['n'], cat: 'Editing', why: 'Core vim muscle memory, untouched.', keys: ['R-R3C3'] },

  // ── Mode Entry ──
  { seq: '<BS>', label: 'insert', desc: 'Enter insert mode here (i)', modes: ['n'], cat: 'Mode Entry', why: 'The left Backspace thumb is insert: no reach, no chord.', keys: [BKSP_ID] },
  { seq: 'Y', label: '⌞ins', desc: 'Insert at the line start (I)', modes: ['n'], cat: 'Mode Entry', why: 'Y replaces I for line-start insert.', keys: [L('y'), ...SH] },
  { seq: '<CR>', label: '+line', desc: 'Open a new line below (o)', modes: ['n'], cat: 'Mode Entry', why: 'The right Enter thumb opens a line below.', keys: [ENTER_ID] },
  { seq: '<S-CR>', label: 'line+', desc: 'Open a new line above (O)', modes: ['n'], cat: 'Mode Entry', why: 'Shift+Enter mirrors Enter; needs the Kitty keyboard protocol (Alacritty sends it).', keys: [ENTER_ID, ...SH] },
  { seq: 'a', label: 'append', desc: 'Append after the cursor [default]', modes: ['n'], cat: 'Mode Entry', why: 'a / A stay default.', keys: [L('a')] },
  { seq: 'A', label: 'Appnd$', desc: 'Append at the end of the line [default]', modes: ['n'], cat: 'Mode Entry', why: 'a / A stay default.', keys: [L('a'), ...SH] },
  { seq: 'v', label: 'visual', desc: 'Enter visual mode [default]', modes: ['n'], cat: 'Mode Entry', why: 'Kept default; visual i is up, so prefer operator forms (di() over vi(.', keys: [L('v')] },
  { seq: '<F13>', label: 'normal', desc: 'Get back to normal mode, from any mode', modes: ALL_MODES, cat: 'Mode Entry', why: 'A dedicated keycode no layer claims: unambiguous, terminal included (replaces <C-\\><C-n>). Also arrives as <S-F3>.', keys: ['R-R3C4'] },

  // ── Files/Buffers ──
  { seq: 'gt', label: 'buf ›', desc: 'Go to the next buffer', modes: ['n'], cat: 'Files/Buffers', why: 'gt / gT reused like tabs, but for buffers.', keys: [L('g'), L('t')] },
  { seq: 'gT', label: '‹ buf', desc: 'Go to the previous buffer', modes: ['n'], cat: 'Files/Buffers', why: 'gt / gT reused like tabs, but for buffers.', keys: [L('g'), L('t'), ...SH] },
  { seq: '<C-e>', label: 'find ⌕', desc: 'Fuzzy-find a file by name', modes: ['n', 'i'], cat: 'Files/Buffers', why: 'Ctrl+E = fuzzy-jump at every layer (same as ^E in zsh); a Ctrl chord works mid-typing.', keys: [L('e'), ...CT] },
  { seq: '<C-f>', label: 'grep ⌕', desc: 'Live-grep file contents', modes: ['n', 'i'], cat: 'Files/Buffers', why: 'Same Ctrl-chord family as find-files; works from insert too.', keys: [L('f'), ...CT] },
  { seq: '<C-b>', label: 'bufs ⌕', desc: 'Fuzzy-switch buffers, MRU first', modes: ['n', 'i'], cat: 'Files/Buffers', why: 'MRU sorted, so <C-b><CR> toggles to the alternate buffer.', keys: [L('b'), ...CT] },
  { seq: '<leader>e', label: 'files', desc: 'Open the file explorer (oil)', modes: ['n'], cat: 'Files/Buffers', why: 'Oil renders the directory as an editable buffer, so the motion layer keeps working.', keys: [SPACE_ID, L('e')] },
  { seq: '<leader>sw', label: 'word ⌕', desc: 'Search for the word under the cursor', modes: ['n'], cat: 'Files/Buffers', why: 'grep_string entry point next to the other finder chords.', keys: [SPACE_ID, L('s'), L('w')] },
  { seq: '<leader>w', label: 'write', desc: 'Write this file', modes: ['n'], cat: 'Files/Buffers', why: 'Space w. Waits timeoutlen because wa shares the prefix — the price of both.', keys: [SPACE_ID, L('w')] },
  { seq: '<leader>wa', label: 'wrt all', desc: 'Write every file', modes: ['n'], cat: 'Files/Buffers', why: 'Space w a, next to write.', keys: [SPACE_ID, L('w'), L('a')] },
  { seq: '<leader>q', label: 'quit', desc: 'Quit the window', modes: ['n'], cat: 'Files/Buffers', why: 'Space q, next to the write binds.', keys: [SPACE_ID, L('q')] },

  // ── Windows/Panes ──
  { seq: '<C-w>o', label: '⇥ →', desc: 'Open a split to the right', modes: ['n'], cat: 'Windows/Panes', why: 'Directional splits matching tmux: <C-w> plus the direction key (n e i o).', keys: [L('w'), L('o'), ...CT] },
  { seq: '<C-w>e', label: '⇥ ↓', desc: 'Open a split below', modes: ['n'], cat: 'Windows/Panes', why: 'Directional splits matching tmux.', keys: [L('w'), L('e'), ...CT] },
  { seq: '<C-w>n', label: '← ⇥', desc: 'Open a split to the left', modes: ['n'], cat: 'Windows/Panes', why: 'Directional splits matching tmux.', keys: [L('w'), L('n'), ...CT] },
  { seq: '<C-w>i', label: '⇥ ↑', desc: 'Open a split above', modes: ['n'], cat: 'Windows/Panes', why: 'Directional splits matching tmux.', keys: [L('w'), L('i'), ...CT] },
  { seq: '<M-n>', label: '◀ foc', desc: 'Focus the split to the left', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+neio = focus (smart-splits). Reaches nvim outside a herdr pane; inside herdr the pane layer takes it.', keys: [L('n'), ...AL] },
  { seq: '<M-e>', label: '▼ foc', desc: 'Focus the split below', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+neio = focus (smart-splits).', keys: [L('e'), ...AL] },
  { seq: '<M-i>', label: '▲ foc', desc: 'Focus the split above', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+neio = focus (smart-splits).', keys: [L('i'), ...AL] },
  { seq: '<M-o>', label: 'foc ▶', desc: 'Focus the split to the right', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+neio = focus (smart-splits).', keys: [L('o'), ...AL] },
  { seq: '<M-C-n>', label: '◀ size', desc: 'Resize the split leftward', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+Ctrl+neio = resize: modifier escalation over focus.', keys: [L('n'), ...AL, ...CT] },
  { seq: '<M-C-e>', label: '▼ size', desc: 'Resize the split downward', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+Ctrl+neio = resize: modifier escalation over focus.', keys: [L('e'), ...AL, ...CT] },
  { seq: '<M-C-i>', label: '▲ size', desc: 'Resize the split upward', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+Ctrl+neio = resize: modifier escalation over focus.', keys: [L('i'), ...AL, ...CT] },
  { seq: '<M-C-o>', label: 'size ▶', desc: 'Resize the split rightward', modes: ['n'], cat: 'Windows/Panes', why: 'Alt+Ctrl+neio = resize: modifier escalation over focus.', keys: [L('o'), ...AL, ...CT] },

  // ── LSP (buffer-local, on LspAttach) ──
  { seq: 'gh', label: 'hover', desc: 'LSP: hover documentation', modes: ['n'], cat: 'LSP', why: 'Hover had no home key left (K is prev-match), so it moved to gh; h means "what is this".', keys: [L('g'), L('h')] },
  { seq: 'gH', label: 'signtr', desc: 'LSP: signature help', modes: ['n'], cat: 'LSP', why: 'Shift variant of hover for signatures.', keys: [L('g'), L('h'), ...SH] },
  { seq: 'gd', label: 'defn', desc: 'LSP: go to definitions (picker)', modes: ['n'], cat: 'LSP', why: 'Single-result jumps go straight there; multi-result actions open Telescope.', keys: [L('g'), L('d')] },
  { seq: 'gD', label: 'decl', desc: 'LSP: go to declaration', modes: ['n'], cat: 'LSP', why: 'Shift variant of gd for declarations.', keys: [L('g'), L('d'), ...SH] },
  { seq: 'gr', label: 'refs', desc: 'LSP: find references (picker)', modes: ['n'], cat: 'LSP', why: 'Bare gr: the stock grn/gra/… binds are deleted so gr never waits timeoutlen.', keys: [L('g'), L('r')] },
  { seq: 'gi', label: 'impl', desc: 'LSP: go to implementations (picker)', modes: ['n'], cat: 'LSP', why: 'Costs vim\'s "insert at last insert position", unused in this layout.', keys: [L('g'), L('i')] },
  { seq: 'gy', label: 'type', desc: 'LSP: go to type definition (picker)', modes: ['n'], cat: 'LSP', why: 'gy was free; keeps navigation on g + mnemonic.', keys: [L('g'), L('y')] },
  { seq: 'gk', label: 'next dx', desc: 'LSP: next diagnostic', modes: ['n'], cat: 'LSP', why: 'Same verb as search: k = next, K = prev.', keys: [L('g'), L('k')] },
  { seq: 'gK', label: 'prev dx', desc: 'LSP: previous diagnostic', modes: ['n'], cat: 'LSP', why: 'Same verb as search; gk cost only display-line-up, unused here.', keys: [L('g'), L('k'), ...SH] },
  { seq: 'ga', label: 'action', desc: 'LSP: code action (range in visual)', modes: NX, cat: 'LSP', why: 'Top-level ga, not only <leader>la: C# fires this constantly and <leader>l* pays the prefix pause.', keys: [L('g'), L('a')] },
  { seq: '<leader>lr', label: 'rename', desc: 'LSP: rename symbol', modes: ['n'], cat: 'LSP', why: 'Deliberate and buffer-wide, so it lives under <leader>l with the rare/destructive rest.', keys: [SPACE_ID, L('l'), L('r')] },
  { seq: '<leader>la', label: 'action', desc: 'LSP: code action', modes: ['n'], cat: 'LSP', why: 'The <leader>l twin of ga for discoverability.', keys: [SPACE_ID, L('l'), L('a')] },
  { seq: '<leader>lf', label: 'format', desc: 'LSP: format buffer', modes: ['n'], cat: 'LSP', why: 'Deliberate formatting under <leader>l.', keys: [SPACE_ID, L('l'), L('f')] },
  { seq: '<leader>ld', label: 'diags', desc: 'LSP: buffer diagnostics (picker)', modes: ['n'], cat: 'LSP', why: 'Buffer-scoped diagnostics next to workspace-wide lD.', keys: [SPACE_ID, L('l'), L('d')] },
  { seq: '<leader>lD', label: 'DIAGS', desc: 'LSP: workspace diagnostics (picker)', modes: ['n'], cat: 'LSP', why: 'Shift variant of ld for all diagnostics.', keys: [SPACE_ID, L('l'), L('d'), ...SH] },
  { seq: '<leader>ls', label: 'syms', desc: 'LSP: document symbols (picker)', modes: ['n'], cat: 'LSP', why: 'Buffer symbols next to workspace symbols lS.', keys: [SPACE_ID, L('l'), L('s')] },
  { seq: '<leader>lS', label: 'SYMS', desc: 'LSP: workspace symbols (picker)', modes: ['n'], cat: 'LSP', why: 'Shift variant of ls for workspace scope.', keys: [SPACE_ID, L('l'), L('s'), ...SH] },
  { seq: '<leader>li', label: 'hints', desc: 'LSP: toggle inlay hints', modes: ['n'], cat: 'LSP', why: 'Hints start off (they shift the line); toggled per buffer.', keys: [SPACE_ID, L('l'), L('i')] },
  { seq: '<leader>lR', label: 'restart', desc: 'LSP: restart server', modes: ['n'], cat: 'LSP', why: 'Stops every client on the buffer and re-edits; the fix when roslyn loses the solution.', keys: [SPACE_ID, L('l'), L('r'), ...SH] },
  { seq: '<C-s>', label: 'signtr', desc: 'LSP: signature help while typing [default]', modes: ['i'], cat: 'LSP', why: 'Insert mode cannot reach g binds, so the stock i_CTRL-S stays as the in-typing help.', keys: [L('s'), ...CT] },

  // ── Git ──
  { seq: '<leader>gg', label: 'lazygit', desc: 'Open lazygit (float)', modes: ['n'], cat: 'Git', why: 'gg = the full repo UI; gitsigns answers per-line questions without leaving the buffer.', keys: [SPACE_ID, L('g')] },
];
