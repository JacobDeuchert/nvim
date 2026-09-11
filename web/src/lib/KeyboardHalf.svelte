<script lang="ts">
  import type { Command } from './commands';
  import { KEY_H, KEY_W, STAGGER_L, STAGGER_R, STEP } from './layout';
  import type { Half, PhysKey } from './layout';

  interface Props {
    side: Half;
    title: string;
    matrix: PhysKey[];
    thumbs: PhysKey[];
    matches: Record<string, Command[]>;
    selected: string | null;
    highlight: Set<string>;
    onSelect: (id: string) => void;
  }

  let { side, title, matrix, thumbs, matches, selected, highlight, onSelect }: Props = $props();

  const stagger = $derived(side === 'L' ? STAGGER_L : STAGGER_R);
  const maxStagger = $derived(Math.max(...stagger));
  const rowsBottom = $derived(maxStagger + 3 * STEP + KEY_H);
  const thumbY = $derived(rowsBottom + 12);
  const H = $derived(thumbY + KEY_H + 6);
  const tilt = $derived(side === 'L' ? -8 : 8);

  const W = 6 * STEP;
  const thumbX0 = (W - (2 * KEY_W + 6)) / 2;

  const pos = (k: PhysKey) => ({ x: k.col * STEP, y: stagger[k.col] + k.row * STEP });

  function count(k: PhysKey): number {
    return matches[k.id]?.length ?? 0;
  }

  function ariaName(k: PhysKey): string {
    const m = matches[k.id] ?? [];
    const base = `${k.legend} key`;
    if (m.length === 0) return k.tap ? `${base}, tap ${k.tap}` : base;
    if (m.length === 1) return `${base}: ${m[0].seq}, ${m[0].desc}`;
    return `${base}: ${m.length} commands`;
  }

  function cls(k: PhysKey): string {
    if (selected === k.id) return 'key sel';
    if (highlight.has(k.id)) return 'key ing';
    if ((matches[k.id]?.length ?? 0) > 0) return 'key match';
    return 'key';
  }

  function activate(k: PhysKey) {
    onSelect(k.id);
  }

  function onKeyDown(e: KeyboardEvent, k: PhysKey) {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      activate(k);
    }
  }
</script>

{#snippet face(k: PhysKey, x: number, y: number)}
  <rect class="frame" x={x} y={y} width={KEY_W} height={KEY_H} rx="7" />
  <text class="legend" x={x + 6} y={y + 15}>{k.legend}</text>
  {#if k.tap}
    <text class="tap" x={x + KEY_W - 6} y={y + KEY_H - 6} text-anchor="end">{k.tap}</text>
  {/if}
  {#if selected === k.id}
    <text class="selmark" x={x + KEY_W - 8} y={y + 16} text-anchor="end">▸</text>
  {/if}
  {@const n = count(k)}
  {#if n === 1}
    <text class="center" x={x + KEY_W / 2} y={y + KEY_H / 2 + 7} text-anchor="middle">
      {matches[k.id][0].label}
    </text>
  {:else if n > 1}
    <circle class="countpill" cx={x + KEY_W / 2} cy={y + KEY_H / 2 + 1} r="12" />
    <text class="countnum" x={x + KEY_W / 2} y={y + KEY_H / 2 + 5} text-anchor="middle">{n}</text>
  {/if}
{/snippet}

<section class="half" aria-label={title}>
  <h2>{title}</h2>
  <svg viewBox={`0 0 ${W} ${H}`} role="group" aria-label={`${title} keys`}>
    {#each matrix as k (k.id)}
      {@const p = pos(k)}
      {#if k.legend}
        <g
          class={cls(k)}
          tabindex="0"
          role="button"
          aria-label={ariaName(k)}
          onclick={() => activate(k)}
          onkeydown={(e) => onKeyDown(e, k)}
        >
          <title>{ariaName(k)}</title>
          {@render face(k, p.x, p.y)}
        </g>
      {:else}
        <g class="key empty-key" aria-hidden="true">
          <rect class="frame" x={p.x} y={p.y} width={KEY_W} height={KEY_H} rx="7" />
        </g>
      {/if}
    {/each}
    <g transform={`rotate(${tilt} ${W / 2} ${thumbY + KEY_H / 2})`}>
      {#each thumbs as k, ti (k.id)}
        {@const tx = thumbX0 + ti * (KEY_W + 6)}
        <g
          class={cls(k)}
          tabindex="0"
          role="button"
          aria-label={ariaName(k)}
          onclick={() => activate(k)}
          onkeydown={(e) => onKeyDown(e, k)}
        >
          <title>{ariaName(k)}</title>
          {@render face(k, tx, thumbY)}
        </g>
      {/each}
    </g>
  </svg>
</section>
