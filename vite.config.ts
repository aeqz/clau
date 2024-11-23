import autoprefixer from 'autoprefixer'
import { defineConfig } from 'vite'
import faviconsInjectPlugin from 'vite-plugin-favicons-inject'

export default defineConfig({
  plugins: [faviconsInjectPlugin('./assets/logo.svg')],
  css: {
    postcss: {
      plugins: [autoprefixer],
    },
  },
})
