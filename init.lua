-- init.lua — entry point for the keyboard-layout neovim config (pure Lua).
-- Port to ~/.config/nvim/. See ../../04-neovim.md for the design + rationale.

-- Leader = Space (Principle 1). Must be set before any leader mappings load.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.keymaps')
-- After keymaps (it deletes neovim's built-in gr*/gO LSP binds) and before
-- lazy: the binds attach on LspAttach, so the file only has to be loaded, not
-- ordered against any plugin.
require('config.lsp')
-- Turns the standalone servers on (lsp/*.lua). After config.lsp so the binding
-- scheme is registered before anything can attach.
require('config.servers')
require('config.lazy')

-- :KeyDrill — flashcard trainer for the binds above (lua/keydrill/). Only
-- registers the commands; nothing runs until asked.
require('keydrill').setup()

require('agentref').setup()

-- Plugin-dependent binds still outstanding (04-neovim.md open decision 3):
--   • flash.nvim        — s / S jump, backward find-char
--   • treesitter        — visual `h` incremental expand
--   • finder + which-key — the <leader> tree (find/git/lsp/buffers/agent/…)
-- LSP is done: config/lsp.lua (gh hover, gd/gr/gi/gy, gk/gK, ga, <leader>l*).
