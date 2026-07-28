<script setup lang="ts">
const props = defineProps<{ modelValue: 'new' | 'popular' }>()
const emit = defineEmits<{ 'update:modelValue': ['new' | 'popular'] }>()
</script>

<template>
  <div class="sortsel">
    <button
      :class="{ active: props.modelValue === 'new' }"
      @click="emit('update:modelValue', 'new')"
    >
      Новые
    </button>
    <button
      :class="{ active: props.modelValue === 'popular' }"
      @click="emit('update:modelValue', 'popular')"
    >
      Популярные
    </button>
  </div>
</template>

<style scoped>
.sortsel {
  display: flex;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 3px;
}
.sortsel button {
  padding: 7px 14px;
  border-radius: 999px;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--text-dim);
}
.sortsel button.active {
  background: var(--surface-3);
  color: var(--text);
}
</style>
