<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import AppTopbar from '@/components/AppTopbar.vue'
import BaseModal from '@/components/BaseModal.vue'
import CategoryChips from '@/components/CategoryChips.vue'
import IdeaCard from '@/components/IdeaCard.vue'
import IdeaComposer from '@/components/IdeaComposer.vue'
import IdeaEditModal from '@/components/IdeaEditModal.vue'
import IdeaModal from '@/components/IdeaModal.vue'
import NameModal from '@/components/NameModal.vue'
import SortToggle from '@/components/SortToggle.vue'
import VoteBudget from '@/components/VoteBudget.vue'
import { plural } from '@/plural'
import { useAuth } from '@/stores/auth'
import { useIdeas } from '@/stores/ideas'
import { useToasts } from '@/stores/toasts'
import type { IdeaPublic } from '@/api/ideas'

const auth = useAuth()
const ideas = useIdeas()
const { toast } = useToasts()

const nameOpen = ref(false)
const openId = ref<string | null>(null)
const editId = ref<string | null>(null)
const removeTarget = ref<IdeaPublic | null>(null)

const blocked = computed(() => auth.me?.blocked ?? false)
const spent = computed(() => ideas.votesLeft === 0)
const openIdea = computed(() => ideas.list.find((i) => i.id === openId.value) ?? null)
const editIdea = computed(() => ideas.list.find((i) => i.id === editId.value) ?? null)

/** Свою идею правит и удаляет только автор, и только пока не заблокирован (§4.6) */
const canManage = (idea: IdeaPublic) => idea.is_mine && !blocked.value

function startEdit(idea: IdeaPublic) {
  openId.value = null
  editId.value = idea.id
}

/** Удалять поздно — объясняем это до модалки, а не после отказа базы */
function askRemove(idea: IdeaPublic) {
  if (!idea.can_delete) {
    toast('Идею уже поддержали коллеги — удалить нельзя, но её можно изменить')
    return
  }
  openId.value = null
  removeTarget.value = idea
}

async function confirmRemove() {
  const target = removeTarget.value
  removeTarget.value = null
  if (target) await ideas.remove(target.id)
}

onMounted(() => ideas.load())
</script>

<template>
  <AppTopbar section="ideas" @rename="nameOpen = true" />

  <div class="wrap">
    <!-- Заблокированный видит понятный баннер, а не молча ломающиеся кнопки (§4.6) -->
    <div v-if="blocked" class="blocked-banner">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="9" />
        <path d="M12 8v5M12 16.5v.01" />
      </svg>
      <span>
        <b>Публикация с вашего аккаунта приостановлена организаторами.</b> Читать идеи и обсуждения
        можно по-прежнему. Если это ошибка — напишите организаторам хакатона.
      </span>
    </div>

    <IdeaComposer v-else />

    <div class="sec-head">
      <h2>Облако идей</h2>
      <span class="count">
        {{ ideas.list.length }} {{ plural(ideas.list.length, ['идея', 'идеи', 'идей']) }}
      </span>
      <p>
        Поддержите понравившиеся идеи, поставив 👍, и жмите «В команду», если интересно поработать
        над этой идеей — так соберутся команды.<br />
        <b>У каждого 5 голосов</b> — потратьте их на то, что действительно хотите увидеть на
        хакатоне. Голос всегда можно снять и переставить. Отметок «В команду» и дополнений — сколько
        угодно.
      </p>
    </div>

    <div class="filters">
      <CategoryChips v-model="ideas.filter" with-all />
    </div>
    <div class="filters">
      <VoteBudget :left="ideas.votesLeft" />
      <div class="spacer"></div>
      <SortToggle v-model="ideas.sort" />
    </div>

    <div class="cloud">
      <div v-if="ideas.loading" class="empty-full">Загружаем идеи…</div>
      <div v-else-if="!ideas.visible.length" class="empty-full">
        Здесь пока пусто. Предложите идею в форме выше.
      </div>
      <template v-else>
        <IdeaCard
          v-for="idea in ideas.visible"
          :key="idea.id"
          :idea="idea"
          :spent="spent"
          :manage="canManage(idea)"
          @open="openId = idea.id"
          @vote="ideas.toggleVote(idea.id)"
          @join="ideas.toggleJoin(idea.id)"
          @edit="startEdit(idea)"
          @remove="askRemove(idea)"
        />
      </template>
    </div>
  </div>

  <NameModal v-if="nameOpen" @close="nameOpen = false" />
  <IdeaModal
    v-if="openIdea"
    :idea="openIdea"
    :spent="spent"
    :manage="canManage(openIdea)"
    @close="openId = null"
    @vote="ideas.toggleVote(openIdea.id)"
    @join="ideas.toggleJoin(openIdea.id)"
    @edit="startEdit(openIdea)"
    @remove="askRemove(openIdea)"
  />
  <IdeaEditModal v-if="editIdea" :idea="editIdea" @close="editId = null" />

  <BaseModal v-if="removeTarget" label="Подтверждение" @close="removeTarget = null">
    <h3>Удалить идею?</h3>
    <p class="msub">
      «{{ removeTarget.title }}» исчезнет из облака навсегда — вернуть её сможет только повторная
      публикация.
    </p>
    <div class="cf-actions">
      <button class="primary" @click="confirmRemove">Удалить</button>
      <button class="btn-quiet" @click="removeTarget = null">Отмена</button>
    </div>
  </BaseModal>
</template>

<style scoped>
.filters {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin: 6px 0 8px;
}
.filters .spacer {
  flex: 1;
  min-width: 8px;
}
.cloud {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  margin: 20px 0 60px;
}
.empty-full {
  grid-column: 1/-1;
  padding: 30px 0;
  color: var(--text-faint);
  font-size: 13px;
}
.blocked-banner {
  display: flex;
  align-items: flex-start;
  gap: 11px;
  background: rgba(248, 113, 113, 0.08);
  border: 1px solid rgba(248, 113, 113, 0.28);
  border-radius: var(--r-md);
  padding: 16px 18px;
  margin-top: 26px;
  font-size: 14px;
  line-height: 1.5;
  color: var(--text-dim);
}
.blocked-banner svg {
  width: 18px;
  height: 18px;
  flex: none;
  margin-top: 1px;
  color: #f87171;
}
.blocked-banner b {
  color: var(--text);
}
.cf-actions {
  display: flex;
  gap: 10px;
}
</style>
