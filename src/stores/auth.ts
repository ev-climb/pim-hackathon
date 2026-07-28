import { defineStore } from 'pinia'
import { ref } from 'vue'
import { fetchMe, getSession, renameMe, signOut, type Me } from '@/api/auth'

export const useAuth = defineStore('auth', () => {
  const me = ref<Me | null>(null)
  const userId = ref<string | null>(null)
  const email = ref('')
  const authed = ref(false)
  const ready = ref(false)

  /** Вызывается один раз перед первой навигацией. */
  async function init() {
    if (ready.value) return
    const session = await getSession()
    authed.value = !!session
    userId.value = session?.user.id ?? null
    email.value = session?.user.email ?? ''
    if (session) {
      try {
        me.value = await fetchMe()
      } catch {
        // Профиля нет — например, вход отклонён триггером доменов
        me.value = null
        authed.value = false
        userId.value = null
        await signOut()
      }
    }
    ready.value = true
  }

  async function rename(name: string) {
    await renameMe(name)
    if (me.value) me.value.display_name = name
  }

  async function leave() {
    await signOut()
    me.value = null
    userId.value = null
    authed.value = false
  }

  /** Голоса пересчитываются оптимистично, чтобы пилюля бюджета не ждала сервер. */
  function addVotesUsed(delta: number) {
    if (me.value) me.value.votes_used += delta
  }

  return { me, userId, email, authed, ready, init, rename, leave, addVotesUsed }
})
