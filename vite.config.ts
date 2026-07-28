import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  // Порт закреплён жёстко: он прописан в Redirect URLs Supabase, и если Vite
  // молча уедет на соседний, Google-вход перестанет возвращаться в приложение.
  // 5173 на машине разработчика занят другим проектом — отсюда 5174.
  server: { port: 5174, strictPort: true },
})
