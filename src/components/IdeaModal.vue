<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import BaseModal from './BaseModal.vue'
import { categoryOf } from '@/catalog'
import { ago, initials } from '@/time'
import { useAuth } from '@/stores/auth'
import { useIdeas } from '@/stores/ideas'
import { useToasts } from '@/stores/toasts'
import type { IdeaPublic } from '@/api/ideas'

const props = defineProps<{ idea: IdeaPublic; spent: boolean; manage: boolean }>()
const emit = defineEmits<{ close: []; vote: []; join: []; edit: []; remove: [] }>()

const auth = useAuth()
const ideas = useIdeas()
const { toast } = useToasts()

const text = ref('')
const busy = ref(false)

const cat = computed(() => categoryOf(props.idea.category))
const label = computed(() =>
  props.idea.category === 'OTHER' && props.idea.custom_label
    ? 'Другое · ' + props.idea.custom_label
    : cat.value.label,
)

onMounted(() => ideas.loadComments(props.idea.id))

async function send() {
  const v = text.value.trim()
  if (v.length < 3) {
    toast('Напишите пару слов')
    return
  }
  busy.value = true
  const ok = await ideas.postComment(props.idea.id, v)
  busy.value = false
  if (ok) text.value = ''
}
</script>

<template>
  <BaseModal wide :label="props.idea.title" @close="emit('close')">
    <button class="mclose" aria-label="Закрыть" @click="emit('close')">✕</button>

    <div class="mhead">
      <span class="tag"><span class="cc" :style="{ background: cat.color }"></span>{{ label }}</span>
      <span
        v-if="props.idea.edited_at"
        class="edited"
        :title="'Автор изменил идею ' + ago(props.idea.edited_at)"
        >изменено</span
      >
    </div>
    <h3 style="margin-top: 10px">{{ props.idea.title }}</h3>
    <p class="msub" style="margin-bottom: 14px">{{ props.idea.description }}</p>

    <div class="mactions">
      <span class="author">
        <span class="mini-av">{{
          props.idea.author_name ? initials(props.idea.author_name) : '?'
        }}</span>
        {{ props.idea.author_name ?? 'Аноним' }}
      </span>
      <button
        class="react"
        :class="{ on: props.idea.has_voted, spent: !props.idea.has_voted && props.spent }"
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
      <button class="react join" :class="{ on: props.idea.has_joined }" @click="emit('join')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8z" />
        </svg>
        {{ props.idea.has_joined ? 'В команде' : 'В команду' }} · {{ props.idea.join_count }}
      </button>
    </div>

    <div v-if="props.manage" class="mine-row">
      <button class="mod" @click="emit('edit')">Изменить идею</button>
      <button class="mod danger" @click="emit('remove')">Удалить</button>
      <span class="mod-note">Это ваша идея</span>
    </div>

    <div class="mscroll">
      <div class="dl" style="margin: 8px 0 2px">Дополнения · {{ props.idea.comment_count }}</div>
      <div v-if="ideas.commentsLoading" class="cmt">
        <div class="empty-people">Загружаем…</div>
      </div>
      <template v-else-if="ideas.comments.length">
        <div v-for="c in ideas.comments" :key="c.id" class="cmt">
          <span class="mini-av">{{ initials(c.author_name) }}</span>
          <div class="cbody">
            <div class="cname">{{ c.author_name }} <span>{{ ago(c.created_at) }}</span></div>
            <div class="ctext">{{ c.text }}</div>
          </div>
        </div>
      </template>
      <div v-else class="cmt">
        <div class="empty-people">Дополнений пока нет. Предложите, чего идее не хватает.</div>
      </div>
    </div>

    <div class="cmt-form">
      <textarea
        v-model="text"
        class="inp"
        placeholder="Чего идее не хватает? Как бы вы её развернули?"
        maxlength="400"
        style="min-height: 66px"
        aria-label="Текст дополнения"
      ></textarea>
      <div class="cmt-send">
        <button class="primary" :disabled="busy" @click="send">Отправить дополнение</button>
        <!-- Дополнения всегда под именем, даже у анонимной идеи (§4.2) -->
        <span class="note">Появится под вашим именем · {{ auth.me?.display_name }}</span>
      </div>
    </div>
  </BaseModal>
</template>

<style scoped>
.mactions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  padding-bottom: 4px;
}
.edited {
  font-size: 11px;
  color: var(--text-faint);
  padding-top: 6px;
  white-space: nowrap;
}
/* Кнопки автора — тем же тоном, что и модерация в рейтинге */
.mine-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin-top: 12px;
}
.mod {
  font-size: 12.5px;
  font-weight: 700;
  padding: 8px 14px;
  border-radius: 9px;
  background: var(--surface-2);
  border: 1px solid var(--border);
  color: var(--text-dim);
  transition: 0.15s;
}
.mod:hover {
  border-color: var(--border-strong);
  color: var(--text);
}
.mod.danger:hover {
  border-color: rgba(248, 113, 113, 0.5);
  color: #f87171;
}
.mod-note {
  font-size: 12px;
  color: var(--text-faint);
  margin-left: auto;
}
.cmt-send {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 10px;
  flex-wrap: wrap;
}
.cmt-send .note {
  font-size: 12.5px;
  color: var(--text-faint);
}
</style>
