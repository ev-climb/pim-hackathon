<script setup lang="ts">
import { nextTick, onMounted, ref } from 'vue'
import BaseModal from './BaseModal.vue'
import { useAuth } from '@/stores/auth'
import { useToasts } from '@/stores/toasts'
import { initials } from '@/time'

const emit = defineEmits<{ close: [] }>()

const auth = useAuth()
const { toast } = useToasts()
const value = ref(auth.me?.display_name ?? '')
const input = ref<HTMLInputElement>()
const busy = ref(false)

onMounted(() => nextTick(() => input.value?.focus()))

async function save() {
  const v = value.value.trim()
  if (v.length < 2) {
    toast('Укажите имя')
    return
  }
  busy.value = true
  try {
    // Имя хранится в профиле и не копируется в записи — подтянется везде само (§4.4)
    await auth.rename(v)
    toast('Имя обновлено')
    emit('close')
  } catch {
    toast('Не получилось сохранить имя')
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <BaseModal label="Имя для коллег" @close="emit('close')">
    <h3>Имя для коллег</h3>
    <p class="msub">
      Подставлено из вашего Google-профиля. Это имя коллеги видят рядом с идеями, голосами и
      дополнениями.
    </p>
    <div class="acct">
      <div class="avatar" style="width: 32px; height: 32px; font-size: 13px">
        {{ initials(auth.me?.display_name ?? '') }}
      </div>
      <div class="em"><b>Ваш аккаунт</b>{{ auth.email }}</div>
    </div>
    <label class="mlabel" for="display-name">Как вас показывать</label>
    <input
      id="display-name"
      ref="input"
      v-model="value"
      class="inp"
      maxlength="40"
      placeholder="Например, Женя из платформы"
      @keyup.enter="save"
    />
    <div class="privacy">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      </svg>
      <span>
        Коллеги видят только это имя. Организаторы видят имя и рабочую почту — чтобы позвать вас в
        команду.
      </span>
    </div>
    <button class="primary" style="width: 100%" :disabled="busy" @click="save">Сохранить</button>
  </BaseModal>
</template>
