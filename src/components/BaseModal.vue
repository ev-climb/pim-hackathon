<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'

const props = defineProps<{ wide?: boolean; label?: string }>()
const emit = defineEmits<{ close: [] }>()

// §5.4: Escape и клик вне закрывают модалку
function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape') emit('close')
}
function onBackdrop(e: MouseEvent) {
  if (e.target === e.currentTarget) emit('close')
}
onMounted(() => document.addEventListener('keydown', onKey))
onUnmounted(() => document.removeEventListener('keydown', onKey))
</script>

<template>
  <div class="modal-bg show" @click="onBackdrop">
    <div
      class="modal"
      :class="{ wide: props.wide }"
      role="dialog"
      aria-modal="true"
      :aria-label="props.label"
    >
      <slot />
    </div>
  </div>
</template>

<style scoped>
.modal-bg {
  position: fixed;
  inset: 0;
  z-index: 80;
  background: rgba(8, 8, 10, 0.74);
  backdrop-filter: blur(6px);
  display: none;
  align-items: center;
  justify-content: center;
  padding: 20px;
}
.modal-bg.show {
  display: flex;
}
.modal {
  position: relative;
  background: var(--surface);
  border: 1px solid var(--border-strong);
  border-radius: var(--r-lg);
  padding: 28px;
  max-width: 430px;
  width: 100%;
  box-shadow: var(--shadow);
  animation: pop 0.25s ease;
}
.modal.wide {
  max-width: 580px;
  max-height: 88vh;
  display: flex;
  flex-direction: column;
  padding: 26px;
}
@keyframes pop {
  from {
    opacity: 0;
    transform: scale(0.96);
  }
  to {
    opacity: 1;
    transform: none;
  }
}
@media (prefers-reduced-motion: reduce) {
  .modal {
    animation: none;
  }
}
</style>
