<script setup lang="ts">
import { computed } from 'vue'
import { VOTE_BUDGET } from '@/catalog'

/** Одно из трёх мест, где объясняется бюджет голосов (§6.7). */
const props = defineProps<{ left: number }>()

const used = computed(() => VOTE_BUDGET - props.left)
const pips = computed(() => Array.from({ length: VOTE_BUDGET }, (_, k) => k < used.value))
</script>

<template>
  <span class="budget" :class="{ out: props.left === 0 }">
    <span class="pips">
      <span v-for="(isUsed, k) in pips" :key="k" class="pip" :class="{ used: isUsed }"></span>
    </span>
    {{
      props.left === 0
        ? 'Голоса закончились — снимите один, чтобы отдать другой'
        : 'Осталось голосов: ' + props.left + ' из ' + VOTE_BUDGET
    }}
  </span>
</template>

<style scoped>
.budget {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 6px 15px 6px 12px;
  font-size: 12.5px;
  color: var(--text-dim);
  font-weight: 600;
}
.budget .pips {
  display: flex;
  gap: 4px;
}
.budget .pip {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: var(--accent);
  transition: 0.2s;
}
.budget .pip.used {
  background: var(--surface-3);
}
.budget.out {
  border-color: rgba(246, 201, 21, 0.45);
  color: var(--accent);
}
</style>
