import autoprefixer from 'autoprefixer'
import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'
import faviconsInjectPlugin from 'vite-plugin-favicons-inject'

export default defineConfig({
  plugins: [elmPlugin(), faviconsInjectPlugin('./assets/logo.svg')],
  css: {
    postcss: {
      plugins: [autoprefixer],
    },
  },
})
