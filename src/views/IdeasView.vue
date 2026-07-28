<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import AppTopbar from '@/components/AppTopbar.vue'
import CategoryChips from '@/components/CategoryChips.vue'
import IdeaCard from '@/components/IdeaCard.vue'
import IdeaComposer from '@/components/IdeaComposer.vue'
import IdeaModal from '@/components/IdeaModal.vue'
import NameModal from '@/components/NameModal.vue'
import SortToggle from '@/components/SortToggle.vue'
import VoteBudget from '@/components/VoteBudget.vue'
import { useAuth } from '@/stores/auth'
import { useIdeas } from '@/stores/ideas'

const auth = useAuth()
const ideas = useIdeas()

const nameOpen = ref(false)
const openId = ref<string | null>(null)

const blocked = computed(() => auth.me?.blocked ?? false)
const spent = computed(() => ideas.votesLeft === 0)
const openIdea = computed(() => ideas.list.find((i) => i.id === openId.value) ?? null)

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
      <span class="count">{{ ideas.list.length }} идей</span>
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
          @open="openId = idea.id"
          @vote="ideas.toggleVote(idea.id)"
          @join="ideas.toggleJoin(idea.id)"
        />
      </template>
    </div>
  </div>

  <NameModal v-if="nameOpen" @close="nameOpen = false" />
  <IdeaModal
    v-if="openIdea"
    :idea="openIdea"
    :spent="spent"
    @close="openId = null"
    @vote="ideas.toggleVote(openIdea.id)"
    @join="ideas.toggleJoin(openIdea.id)"
  />
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
</style>
