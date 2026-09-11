<script lang="ts">
  import type { Command } from './commands';
  import { MODES } from './commands';
  import type { PhysKey } from './layout';

  interface Props {
    selectedKey: PhysKey | null;
    commands: Command[];
    hovered: Command | null;
    onClear: () => void;
    onHover: (c: Command | null) => void;
  }

  let { selectedKey, commands, hovered, onClear, onHover }: Props = $props();

  const modeName = (id: string) => MODES.find((m) => m.id === id)?.name ?? id;
</script>

<aside class="detail" aria-label="Selected key details" aria-live="polite">
  <h2>
    <span>Details</span>
    {#if selectedKey}
      <button class="clear" onclick={onClear}>Clear ✕</button>
    {/if}
  </h2>
  {#if selectedKey}
    <p class="dhead">
      key <strong>{selectedKey.legend || selectedKey.id}</strong>
      · {commands.length} filtered {commands.length === 1 ? 'sequence' : 'sequences'}
    </p>
    {#if commands.length === 0}
      <p class="empty-note">No filtered sequences involve this key. Widen the mode or intent filter.</p>
    {/if}
    <div role="list">
    {#each commands as c (c.seq + c.cat)}
      <div
        class="drow"
        class:lit={hovered?.seq === c.seq && hovered?.cat === c.cat}
        role="listitem"
        onmouseenter={() => onHover(c)}
        onmouseleave={() => onHover(null)}
      >
        <span class="seq">{c.seq}</span>
        <div class="tags">
          <span class="cat">{c.cat}</span>
          {#each c.modes as m (m)}
            <span class="mode">{modeName(m)}</span>
          {/each}
        </div>
        <p class="desc">{c.desc}</p>
        <p class="why">{c.why}</p>
      </div>
    {/each}
    </div>
  {:else}
    <p class="empty-note">
      Select a key — by pointer, <kbd>Tab</kbd> + <kbd>Enter</kbd>, or by pressing the
      physical key — to list every filtered sequence involving it.
    </p>
  {/if}
</aside>
