<script setup lang="ts">
import { CATEGORIES } from '@/catalog'

/** Один компонент на два места: фильтр облака (с чипом «Все») и выбор в форме. */
const props = defineProps<{ modelValue: string; withAll?: boolean }>()
const emit = defineEmits<{ 'update:modelValue': [string] }>()
</script>

<template>
  <div class="cat-pick">
    <button
      v-if="props.withAll"
      class="chip"
      :class="{ active: props.modelValue === 'all' }"
      @click="emit('update:modelValue', 'all')"
    >
      Все
    </button>
    <button
      v-for="c in CATEGORIES"
      :key="c.id"
      class="chip"
      :class="{ active: props.modelValue === c.id }"
      @click="emit('update:modelValue', c.id)"
    >
      <span class="cc" :style="{ background: c.color }"></span>{{ c.label }}
    </button>
  </div>
</template>

<style scoped>
.cat-pick {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
</style>
