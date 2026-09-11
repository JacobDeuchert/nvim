<script lang="ts">
  import DetailPanel from './lib/DetailPanel.svelte';
  import FilterBar from './lib/FilterBar.svelte';
  import KeyboardHalf from './lib/KeyboardHalf.svelte';
  import type { Category, Command, Mode } from './lib/commands';
  import { COMMANDS, MODES } from './lib/commands';
  import {
    EXLM_SLOT_ID,
    KEY_BY_ID,
    LEFT_KEYS,
    LEFT_THUMBS,
    LETTER_KEY,
    QST_SLOT_ID,
    RIGHT_KEYS,
    RIGHT_THUMBS,
    UNDERSCORE_SLOT_ID,
  } from './lib/layout';

  let activeMode = $state<Mode>('n');
  let activeCat = $state<Category | 'all'>('all');
  let selected = $state<string | null>(null);
  let hovered = $state<Command | null>(null);

  const visible = $derived(
    COMMANDS.filter(
      (c) => c.modes.includes(activeMode) && (activeCat === 'all' || c.cat === activeCat),
    ),
  );

  const matches = $derived.by<Record<string, Command[]>>(() => {
    const m: Record<string, Command[]> = {};
    for (const c of visible) {
      for (const id of c.keys) {
        (m[id] ??= []).push(c);
      }
    }
    return m;
  });

  const selectedMatches = $derived(
    selected ? visible.filter((c) => c.keys.includes(selected!)) : [],
  );

  const highlight = $derived.by<Set<string>>(() => {
    if (hovered) return new Set(hovered.keys);
    if (selected) return new Set(selectedMatches.flatMap((c) => c.keys));
    return new Set();
  });

  const selectedKey = $derived(selected ? (KEY_BY_ID[selected] ?? null) : null);
  const modeName = $derived(MODES.find((m) => m.id === activeMode)?.name ?? activeMode);

  function toggleSelect(id: string) {
    selected = selected === id ? null : id;
  }

  function physicalIdForEvent(e: KeyboardEvent): string | null {
    if (['Control', 'Shift', 'Alt', 'Meta'].includes(e.key)) return null;
    switch (e.key) {
      case ' ': return 'L-T0';
      case 'Enter': return 'R-T1';
      case 'Backspace': return 'L-T1';
      case 'Delete': return 'R-T0';
      case 'Tab': return 'L-R2C0';
      case 'Escape': return 'L-R1C0';
      case 'F13': return 'R-R3C4';
      case '!': return EXLM_SLOT_ID;
      case '?': return QST_SLOT_ID;
      case '_': return UNDERSCORE_SLOT_ID;
    }
    if (e.key.length === 1) {
      const up = e.key.toUpperCase();
      if (LETTER_KEY[up]) return LETTER_KEY[up];
      const sym = Object.values(KEY_BY_ID).find((k) => k.legend === e.key);
      if (sym) return sym.id;
    }
    return null;
  }

  $effect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')) return;
      const id = physicalIdForEvent(e);
      if (id && KEY_BY_ID[id]?.legend !== '') toggleSelect(id);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });
</script>

<header class="top">
  <h1>Voyager <span class="x">x</span> Neovim</h1>
  <p class="sub">
    Physical Colemak-DH layout → curated Neovim working set of this repo.
    Showing {visible.length} of {COMMANDS.length} commands · mode {modeName} ·
    {activeCat === 'all' ? 'all intents' : activeCat}.
  </p>
</header>

<FilterBar
  {activeMode}
  {activeCat}
  onMode={(m) => { activeMode = m; }}
  onCat={(c) => { activeCat = c; }}
/>

<div class="layout">
  <div class="board">
    <KeyboardHalf
      side="L"
      title="Left half"
      matrix={LEFT_KEYS}
      thumbs={LEFT_THUMBS}
      {matches}
      {selected}
      {highlight}
      onSelect={toggleSelect}
    />
    <KeyboardHalf
      side="R"
      title="Right half"
      matrix={RIGHT_KEYS}
      thumbs={RIGHT_THUMBS}
      {matches}
      {selected}
      {highlight}
      onSelect={toggleSelect}
    />
  </div>
  <DetailPanel
    {selectedKey}
    commands={selectedMatches}
    {hovered}
    onClear={() => { selected = null; }}
    onHover={(c) => { hovered = c; }}
  />
</div>

<footer class="foot">
  <p>
    Click a keycap, <kbd>Tab</kbd> to it and press <kbd>Enter</kbd>, or press the physical
    key. Browser-reserved chords (e.g. <kbd>Ctrl</kbd>+<kbd>W</kbd>) cannot be captured —
    pointer selection is the reliable fallback. Amber outline + ▸ marks the selected key;
    selection never relies on color alone.
  </p>
</footer>
