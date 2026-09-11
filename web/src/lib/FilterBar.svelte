<script lang="ts">
  import type { Category, Mode } from './commands';
  import { CATEGORIES, MODES } from './commands';

  interface Props {
    activeMode: Mode;
    activeCat: Category | 'all';
    onMode: (m: Mode) => void;
    onCat: (c: Category | 'all') => void;
  }

  let { activeMode, activeCat, onMode, onCat }: Props = $props();
</script>

<div class="filters">
  <div class="fgroup" role="group" aria-label="Neovim mode filter">
    <span class="fname">Mode</span>
    {#each MODES as m (m.id)}
      <button
        class="chip"
        aria-pressed={activeMode === m.id}
        onclick={() => onMode(m.id)}
      >
        {m.name}
      </button>
    {/each}
  </div>
  <div class="fgroup" role="group" aria-label="Intent category filter">
    <span class="fname">Intent</span>
    <button
      class="chip"
      aria-pressed={activeCat === 'all'}
      onclick={() => onCat('all')}
    >
      All
    </button>
    {#each CATEGORIES as c (c)}
      <button
        class="chip"
        aria-pressed={activeCat === c}
        onclick={() => onCat(c)}
      >
        {c}
      </button>
    {/each}
  </div>
</div>
