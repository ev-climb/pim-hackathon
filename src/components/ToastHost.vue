<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { useToasts } from '@/stores/toasts'

const { text, shown } = storeToRefs(useToasts())
</script>

<template>
  <div class="toast" :class="{ show: shown }" role="status" aria-live="polite">{{ text }}</div>
</template>

<style scoped>
.toast {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%) translateY(20px);
  opacity: 0;
  background: var(--accent);
  color: var(--accent-ink);
  font-weight: 700;
  font-size: 14px;
  padding: 12px 20px;
  border-radius: 12px;
  box-shadow: var(--shadow);
  transition: 0.3s;
  z-index: 99;
  pointer-events: none;
  max-width: 90vw;
  text-align: center;
}
.toast.show {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
}
</style>
