import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useToasts = defineStore('toasts', () => {
  const text = ref('')
  const shown = ref(false)
  let timer: ReturnType<typeof setTimeout> | undefined

  function toast(message: string) {
    text.value = message
    shown.value = true
    clearTimeout(timer)
    timer = setTimeout(() => (shown.value = false), 2400)
  }

  return { text, shown, toast }
})
