import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !key) {
  throw new Error(
    'Нет VITE_SUPABASE_URL или VITE_SUPABASE_ANON_KEY. Заполните .env.local — ключ лежит в Supabase → Settings → API.',
  )
}

// Единственное место в проекте, где создаётся клиент. В компонентах и сторах
// его не импортируют — только через модули src/api (§2, задел на переезд).
export const supabase = createClient(url, key)
