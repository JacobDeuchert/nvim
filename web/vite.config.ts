import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

// Spread: svelte() returns an array of plugins, and svelte-check only
// detects the Svelte setup in a flat plugins list.
export default defineConfig({
  plugins: [...svelte()],
});
