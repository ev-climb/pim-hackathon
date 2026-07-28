<script setup lang="ts">
import { computed } from 'vue'
import { categoryOf } from '@/catalog'
import { initials } from '@/time'
import type { IdeaPublic } from '@/api/ideas'

const props = defineProps<{ idea: IdeaPublic; spent: boolean }>()
const emit = defineEmits<{ open: []; vote: []; join: [] }>()

const cat = computed(() => categoryOf(props.idea.category))
// «Другое · <тема>», если тема заполнена, иначе просто «Другое» (§4.5)
const label = computed(() =>
  props.idea.category === 'OTHER' && props.idea.custom_label
    ? 'Другое · ' + props.idea.custom_label
    : cat.value.label,
)
</script>

<template>
  <article class="idea">
    <span class="tag"><span class="cc" :style="{ background: cat.color }"></span>{{ label }}</span>
    <h4 @click="emit('open')">{{ props.idea.title }}</h4>
    <p class="desc">{{ props.idea.description }}</p>
    <button class="cbtn" :class="{ has: props.idea.comment_count }" @click="emit('open')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path
          d="M21 11.5a8.4 8.4 0 01-9 8.4 8.5 8.5 0 01-3.8-.9L3 21l1.9-5.2A8.4 8.4 0 013.6 8 8.5 8.5 0 0112 3.5a8.4 8.4 0 019 8z"
        />
      </svg>
      {{
        props.idea.comment_count
          ? 'Дополнения · ' + props.idea.comment_count
          : 'Предложить дополнение'
      }}
    </button>
    <div class="foot">
      <span class="author">
        <span class="mini-av">{{
          props.idea.author_name ? initials(props.idea.author_name) : '?'
        }}</span>
        {{ props.idea.author_name ?? 'Аноним' }}
      </span>
      <button
        class="react"
        :class="{ on: props.idea.has_voted, spent: !props.idea.has_voted && props.spent }"
        :title="props.idea.has_voted ? 'Снять голос' : 'Отдать голос'"
        :aria-label="props.idea.has_voted ? 'Снять голос' : 'Отдать голос'"
        @click="emit('vote')"
      >
        <svg
          viewBox="0 0 24 24"
          :fill="props.idea.has_voted ? 'currentColor' : 'none'"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            d="M7 10v11M2 13v6a2 2 0 002 2h13.3a2 2 0 002-1.6l1.4-7a2 2 0 00-2-2.4H14V6a2.5 2.5 0 00-2.5-2.5L8 12H7"
          />
        </svg>
        {{ props.idea.vote_count }}
      </button>
      <button
        class="react join"
        :class="{ on: props.idea.has_joined }"
        title="Готов поработать над идеей"
        @click="emit('join')"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path
            d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8zM23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"
          />
        </svg>
        {{ props.idea.has_joined ? 'В команде' : 'В команду' }} · {{ props.idea.join_count }}
      </button>
    </div>
  </article>
</template>

<style scoped>
.idea {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: 0.2s;
}
.idea:hover {
  border-color: var(--border-strong);
  transform: translateY(-3px);
  box-shadow: var(--shadow);
}
.idea h4 {
  margin: 0;
  font-size: 17px;
  font-weight: 800;
  line-height: 1.25;
  cursor: pointer;
}
.idea h4:hover {
  color: var(--accent);
}
.idea .desc {
  color: var(--text-dim);
  font-size: 14px;
  line-height: 1.55;
  margin: 0;
  flex: 1;
}
.cbtn {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--text-faint);
  padding: 0;
  align-self: flex-start;
  transition: 0.15s;
}
.cbtn:hover {
  color: var(--accent);
}
.cbtn.has {
  color: var(--accent);
}
.cbtn svg {
  width: 14px;
  height: 14px;
}
.idea .foot {
  display: flex;
  align-items: center;
  gap: 10px;
  padding-top: 12px;
  border-top: 1px solid var(--border);
  flex-wrap: wrap;
}
@media (prefers-reduced-motion: reduce) {
  .idea:hover {
    transform: none;
  }
}
</style>
