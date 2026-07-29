<script setup lang="ts">
import BaseModal from './BaseModal.vue'
import IdeaComposer from './IdeaComposer.vue'
import type { IdeaPublic } from '@/api/ideas'

const props = defineProps<{ idea: IdeaPublic }>()
const emit = defineEmits<{ close: [] }>()
</script>

<template>
  <BaseModal wide label="Изменить идею" @close="emit('close')">
    <button class="mclose" aria-label="Закрыть" @click="emit('close')">✕</button>
    <div class="escroll">
      <IdeaComposer :edit="props.idea" @done="emit('close')" />
    </div>
  </BaseModal>
</template>

<style scoped>
/* Модалка ограничена 88vh: на 375px форма должна скроллиться внутри неё */
.escroll {
  overflow-y: auto;
  padding-right: 2px;
}
</style>
