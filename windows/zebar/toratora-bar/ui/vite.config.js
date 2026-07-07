import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // Zebar loads the built html from disk → relative paths required
  base: './',
  build: {
    outDir: '../toratora-widget',
    emptyOutDir: true,
    target: 'es2020',
  },
});
