# Voyager x Neovim Cheatsheet Plan

## Goal

Build a local web app that maps the physical ZSA Voyager layout to the curated
Neovim commands used by this repository. The app is a visual reference, not a
replacement for the existing in-editor KeyDrill trainer.

## Project Structure

- Create the app under `web/` so the Neovim configuration remains the repository
  root concern.
- Use Svelte 5, Vite, TypeScript, npm, and custom CSS.
- Keep the command catalogue owned by the web app and update it manually when
  the Neovim configuration changes.
- Use the supplied Oryx/QMK export as the source for physical key positions,
  legends, hold-tap modifiers, layer-taps, and thumb keys.
- Do not require the source ZIP at runtime.

## Content Scope

- Include only mappings implemented in the checked-in Neovim configuration.
- Include important default Neovim commands intentionally retained by the
  custom layout.
- Include mappings used in editing contexts: global, LSP-buffer, Visual,
  Operator-pending, Insert, Terminal, and Command-line mappings.
- Exclude controls that only operate inside plugin interfaces such as Telescope
  or lazygit.
- Exclude mappings mentioned only as plans or TODOs, including unfinished Flash
  and Treesitter bindings.
- Include implemented mappings currently absent from the KeyDrill catalogue,
  including `Ctrl-f`, `Space s w`, and the LSP bindings.

## Information Model

Each command entry should define:

- Full key sequence.
- Short action label suitable for a keycap.
- Complete action description.
- Applicable Neovim modes.
- Intent-based category.
- Concise ergonomic or mnemonic rationale.
- Physical keys involved, including alternative modifier keys where applicable.

Use these categories:

- Movement
- Search
- Editing
- Mode Entry
- Files/Buffers
- Windows/Panes
- LSP
- Git

Expose these mode filters:

- Normal
- Visual
- Operator-pending
- Insert
- Terminal
- Command-line

Select mode may be described alongside Visual behavior rather than receiving a
separate top-level filter.

## Interface

- Title the app **Voyager x Neovim**.
- Use a dark, low-glare technical display inspired by an editor instrument
  panel rather than copying the Oryx interface.
- Render precise Voyager stagger and angled thumb geometry as scalable SVG.
- Preserve the base physical legend in a keycap corner.
- Show a short action label in the keycap center when a command matches the
  active filters.
- Show a count instead of crowding the keycap when several commands match.
- Default to Normal mode with all categories visible.
- Allow one intent category or all categories at a time.
- Allow key selection by pointer or physical keyboard input.
- Selecting a physical key should show every filtered sequence involving that
  key, not only sequences beginning with it.
- For modifier chords, highlight every physical ingredient. For example,
  `Ctrl-e` highlights `E` and both available Ctrl hold-tap keys.
- Present the selected key's matching commands in a detail panel with sequence,
  action, modes, and rationale.
- Treat browser-reserved shortcuts as best-effort physical input and preserve
  pointer selection as the reliable fallback.

## Responsive Behavior

- Keep both keyboard halves in their physical side-by-side arrangement on wide
  screens.
- Stack the left and right halves vertically when the viewport is too narrow to
  keep labels readable.
- Place command details below the keyboard on narrow screens.
- Keep every interactive key keyboard-focusable and provide accessible names.
- Do not rely on color alone to communicate selection or category.

## Explicit Non-Goals

- Browser-based drills, scoring, or statistics.
- Full documentation of every Neovim default command.
- Complete visualization of all Voyager firmware layers.
- Parsing Lua configuration during the web build.
- Sharing a command-data source with KeyDrill.
- Text search or a command palette in the initial version.
- Persisting filters or selection in local storage.
- Hosting or deployment automation.
- A UI component library or utility-CSS framework.
- End-to-end browser tests in the initial version.

## Verification

- Install dependencies with npm from `web/`.
- Run Svelte type-checking successfully.
- Produce a successful Vite production build.
- Manually verify click selection, physical key selection, mode/category
  filtering, modifier highlighting, and narrow-screen stacking.

## Completion Criteria

The first version is complete when it can be run locally, accurately reproduces
the supplied Voyager base layout, represents the implemented curated Neovim
working set, and lets a user locate a command by mode, intent, and physical key
without consulting the Lua configuration.
