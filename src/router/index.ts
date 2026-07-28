import { createRouter, createWebHistory } from 'vue-router'
import { useAuth } from '@/stores/auth'
import LoginView from '@/views/LoginView.vue'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', name: 'login', component: LoginView },
    { path: '/ideas', name: 'ideas', component: () => import('@/views/IdeasView.vue') },
    { path: '/admin', name: 'admin', component: () => import('@/views/AdminView.vue') },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

// Гвард глобальный. Сотрудник на /admin уезжает на /ideas — и данных всё равно
// не получит, политики вернут пусто (§5.1).
router.beforeEach(async (to) => {
  const auth = useAuth()
  await auth.init()

  if (!auth.authed) return to.name === 'login' ? true : { name: 'login' }
  if (to.name === 'login') return { name: 'ideas' }
  if (to.name === 'admin' && !auth.me?.is_admin) return { name: 'ideas' }
  return true
})
