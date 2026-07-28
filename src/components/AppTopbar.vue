<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/stores/auth'
import { initials } from '@/time'

const props = defineProps<{ section: 'ideas' | 'admin' }>()
const emit = defineEmits<{ rename: [] }>()

const auth = useAuth()
const router = useRouter()
const name = computed(() => auth.me?.display_name ?? '')

// Меню на аватаре — единственное место, где до смены имени и выхода можно
// добраться на любой ширине: блок .who на мобильных скрыт.
const menuOpen = ref(false)
const menuHost = ref<HTMLElement>()

function onDocClick(e: MouseEvent) {
  if (!menuHost.value?.contains(e.target as Node)) menuOpen.value = false
}
function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape') menuOpen.value = false
}

watch(menuOpen, (open) => {
  if (open) {
    document.addEventListener('click', onDocClick)
    document.addEventListener('keydown', onKey)
  } else {
    document.removeEventListener('click', onDocClick)
    document.removeEventListener('keydown', onKey)
  }
})
onUnmounted(() => {
  document.removeEventListener('click', onDocClick)
  document.removeEventListener('keydown', onKey)
})

function rename() {
  menuOpen.value = false
  emit('rename')
}

async function leave() {
  menuOpen.value = false
  await auth.leave()
  router.push('/')
}
</script>

<template>
  <div class="topbar">
    <div class="wrap">
      <div class="row">
        <div class="brand"><span class="dot"></span>PIM <span>&nbsp;Hackathon</span></div>
        <!-- Организатор — такой же сотрудник, поэтому у него переключатель разделов (§5.1) -->
        <nav v-if="auth.me?.is_admin" class="tabs">
          <button :class="{ active: props.section === 'ideas' }" @click="router.push('/ideas')">
            Облако идей
          </button>
          <button :class="{ active: props.section === 'admin' }" @click="router.push('/admin')">
            Рейтинг
          </button>
        </nav>

        <div class="topbar-right">
          <div class="who">
            <b>{{ name }}</b>
            <small v-if="props.section === 'admin'">организатор</small>
            <button v-else @click="emit('rename')">Изменить имя</button>
          </div>

          <div ref="menuHost" class="user-menu">
            <button
              class="avatar"
              aria-haspopup="menu"
              :aria-expanded="menuOpen"
              :aria-label="'Меню аккаунта · ' + name"
              @click="menuOpen = !menuOpen"
            >
              {{ initials(name) }}
            </button>

            <div v-if="menuOpen" class="menu" role="menu">
              <div class="menu-head">
                <b>{{ name }}</b>
                <span class="mail">{{ auth.email }}</span>
              </div>
              <button class="menu-item" role="menuitem" @click="rename">Изменить имя</button>
              <button class="menu-item" role="menuitem" @click="leave">Выйти</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.topbar {
  position: relative;
  border-bottom: 1px solid var(--border);
  background: linear-gradient(180deg, #141416, #0f0f11);
}
.topbar .row {
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 16px 0;
}
.brand {
  display: flex;
  align-items: center;
  gap: 11px;
  font-family: 'Archivo Expanded', sans-serif;
  font-weight: 900;
  font-size: 19px;
  letter-spacing: -0.01em;
}
.brand .dot {
  width: 11px;
  height: 11px;
  background: var(--accent);
  border-radius: 3px;
}
.brand span {
  color: var(--accent);
}
.tabs {
  display: flex;
  gap: 4px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 3px;
}
.tabs button {
  padding: 7px 15px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-dim);
  transition: 0.16s;
}
.tabs button:hover {
  color: var(--text);
}
.tabs button.active {
  background: var(--accent);
  color: var(--accent-ink);
}
.topbar-right {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 12px;
}
.who {
  font-size: 13px;
  text-align: right;
}
.who b {
  display: block;
}
.who small {
  color: var(--text-faint);
}
.who button {
  font-size: 11.5px;
  color: var(--text-faint);
  text-decoration: underline;
  padding: 0;
}
.who button:hover {
  color: var(--accent);
}

.user-menu {
  position: relative;
}
.user-menu .avatar {
  padding: 0; /* аватар стал кнопкой — снимаем браузерный отступ */
  transition: 0.16s;
}
.user-menu .avatar:hover {
  background: linear-gradient(135deg, var(--accent-hi), var(--accent));
}
.menu {
  position: absolute;
  top: calc(100% + 10px);
  right: 0;
  z-index: 70;
  min-width: 216px;
  background: var(--surface);
  border: 1px solid var(--border-strong);
  border-radius: var(--r-md);
  box-shadow: var(--shadow);
  padding: 6px;
  animation: menu-in 0.16s ease;
}
@keyframes menu-in {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: none;
  }
}
@media (prefers-reduced-motion: reduce) {
  .menu {
    animation: none;
  }
}
.menu-head {
  padding: 9px 11px 11px;
  border-bottom: 1px solid var(--border);
  margin-bottom: 6px;
}
.menu-head b {
  display: block;
  font-size: 13.5px;
  font-weight: 700;
}
.menu-head .mail {
  display: block;
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--text-faint);
  margin-top: 3px;
  overflow-wrap: anywhere;
}
.menu-item {
  display: block;
  width: 100%;
  text-align: left;
  padding: 9px 11px;
  border-radius: 9px;
  font-size: 13.5px;
  font-weight: 600;
  color: var(--text-dim);
  transition: 0.14s;
}
.menu-item:hover {
  background: var(--surface-2);
  color: var(--text);
}
@media (max-width: 760px) {
  .who {
    display: none;
  }
}

/* Узкие экраны: у организатора в шапке разом бренд, переключатель разделов
   и аватар — на 390px в одну строку это не влезает. Сначала поджимаем размеры. */
@media (max-width: 560px) {
  .topbar .row {
    gap: 10px;
    padding: 12px 0;
  }
  .brand {
    font-size: 16px;
    gap: 8px;
  }
  .brand .dot {
    width: 9px;
    height: 9px;
  }
  .tabs {
    padding: 2px;
  }
  .tabs button {
    font-size: 12px;
    padding: 6px 12px;
  }
  .avatar {
    width: 32px;
    height: 32px;
    font-size: 13px;
  }
}

/* Ещё уже — дальше уменьшать шрифты некуда без потери читаемости,
   поэтому переключатель уезжает на вторую строку во всю ширину. */
@media (max-width: 430px) {
  .topbar .row {
    flex-wrap: wrap;
  }
  .brand {
    order: 1;
  }
  .topbar-right {
    order: 2;
  }
  .tabs {
    order: 3;
    width: 100%;
  }
  .tabs button {
    flex: 1;
    text-align: center;
  }
}
</style>
