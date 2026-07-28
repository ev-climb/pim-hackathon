<script setup lang="ts">
const props = defineProps<{
  ideas: number
  people: number
  votes: number
  topCategory: string
}>()
</script>

<template>
  <div class="kpis">
    <div class="kpi">
      <div class="kv">{{ props.ideas }}</div>
      <div class="kl">идей предложено</div>
    </div>
    <div class="kpi">
      <div class="kv">{{ props.people }}</div>
      <div class="kl">сотрудников поучаствовало</div>
    </div>
    <div class="kpi">
      <div class="kv">{{ props.votes }}</div>
      <div class="kl">голосов отдано</div>
    </div>
    <div class="kpi plain">
      <div class="kv">{{ props.topCategory }}</div>
      <div class="kl">самая популярная категория</div>
    </div>
  </div>
</template>

<style scoped>
.kpis {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
  margin: 26px 0 8px;
}
@media (max-width: 760px) {
  .kpis {
    grid-template-columns: repeat(2, 1fr);
  }
}
.kpi {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  padding: 18px;
  position: relative;
  overflow: hidden;
}
.kpi::after {
  content: '';
  position: absolute;
  right: -16px;
  top: -16px;
  width: 70px;
  height: 70px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(246, 201, 21, 0.12), transparent 70%);
}
.kpi .kv {
  font-family: 'Archivo Expanded', sans-serif;
  font-weight: 900;
  font-size: 34px;
  line-height: 1;
  color: var(--accent);
}
.kpi .kl {
  font-size: 12px;
  color: var(--text-dim);
  margin-top: 8px;
}
.kpi.plain .kv {
  color: var(--text);
  font-size: 21px;
  font-family: 'Archivo', sans-serif;
  line-height: 1.2;
}
</style>
