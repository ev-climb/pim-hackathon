<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import AppTopbar from '@/components/AppTopbar.vue'
import BaseModal from '@/components/BaseModal.vue'
import KpiCards from '@/components/KpiCards.vue'
import RankRow from '@/components/RankRow.vue'
import { CATEGORIES } from '@/catalog'
import { useAdmin } from '@/stores/admin'
import type { RankIdea } from '@/stores/admin'

const admin = useAdmin()

// Скрытие обратимо и подтверждения не требует, блокировка требует (§5.1)
const blockTarget = ref<RankIdea | null>(null)

/** Номер в рейтинге считается только по видимым идеям, у скрытых прочерк. */
const ranked = computed(() => {
  let n = 0
  return admin.filtered.map((idea) => ({ idea, rank: idea.hidden ? null : ++n }))
})

const confirmText = computed(() => {
  const t = blockTarget.value
  if (!t) return ''
  return t.authorBlocked
    ? t.authorName + ' снова сможет предлагать идеи, голосовать и писать дополнения.'
    : t.authorName +
        ' сможет читать идеи и обсуждения, но не сможет ничего публиковать и голосовать. Уже поданные идеи останутся — скрывайте их отдельно.'
})

async function confirmBlock() {
  const t = blockTarget.value
  blockTarget.value = null
  if (t) await admin.toggleBlocked(t.author_id)
}

onMounted(() => admin.load())
</script>

<template>
  <AppTopbar section="admin" />

  <div class="wrap">
    <KpiCards
      :ideas="admin.kpi.ideas"
      :people="admin.kpi.people"
      :votes="admin.kpi.votes"
      :top-category="admin.kpi.topCategory"
    />

    <div class="sec-head" style="margin-bottom: 6px">
      <h2>Рейтинг идей</h2>
      <p>
        Самые популярные — сверху. Разверните строку, чтобы увидеть автора с почтой, кто голосовал,
        кто готов в команду и все дополнения.
      </p>
    </div>

    <div class="admin-controls">
      <div class="search">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="7" />
          <path d="M21 21l-4-4" />
        </svg>
        <input
          v-model="admin.search"
          placeholder="Поиск по названию, автору или почте…"
          aria-label="Поиск по рейтингу"
        />
      </div>
      <select v-model="admin.category" class="selbox" aria-label="Фильтр по категории">
        <option value="all">Все категории</option>
        <option v-for="c in CATEGORIES" :key="c.id" :value="c.id">{{ c.label }}</option>
      </select>
      <select v-model="admin.sort" class="selbox" aria-label="Сортировка">
        <option value="likes">По голосам</option>
        <option value="joins">По желающим в команду</option>
        <option value="cmts">По дополнениям</option>
        <option value="new">По дате</option>
      </select>
    </div>

    <div class="rank-list">
      <div v-if="admin.loading" class="empty-people" style="padding: 24px">Загружаем рейтинг…</div>
      <div v-else-if="!ranked.length" class="empty-people" style="padding: 24px">
        Ничего не нашлось. Измените запрос или фильтр.
      </div>
      <template v-else>
        <RankRow
          v-for="row in ranked"
          :key="row.idea.id"
          :idea="row.idea"
          :rank="row.rank"
          :open="admin.openRow === row.idea.id"
          @toggle="admin.toggleRow(row.idea.id)"
          @status="admin.changeStatus(row.idea.id, $event)"
          @hide="admin.toggleHidden(row.idea.id)"
          @block="blockTarget = row.idea"
        />
      </template>
    </div>
  </div>

  <BaseModal v-if="blockTarget" label="Подтверждение" @close="blockTarget = null">
    <h3>{{ blockTarget.authorBlocked ? 'Разблокировать автора?' : 'Заблокировать автора?' }}</h3>
    <p class="msub">{{ confirmText }}</p>
    <div class="cf-actions">
      <button class="primary" @click="confirmBlock">
        {{ blockTarget.authorBlocked ? 'Разблокировать' : 'Заблокировать' }}
      </button>
      <button class="btn-quiet" @click="blockTarget = null">Отмена</button>
    </div>
  </BaseModal>
</template>

<style scoped>
.admin-controls {
  display: flex;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
  margin: 22px 0 14px;
}
.search {
  flex: 1;
  min-width: 200px;
  display: flex;
  align-items: center;
  gap: 9px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 11px;
  padding: 0 14px;
}
.search input {
  background: none;
  border: none;
  outline: none;
  color: var(--text);
  font-size: 14px;
  padding: 12px 0;
  width: 100%;
}
.search svg {
  width: 16px;
  height: 16px;
  color: var(--text-faint);
  flex: none;
}
.selbox {
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text-dim);
  border-radius: 11px;
  padding: 12px 14px;
  font-size: 13.5px;
  font-weight: 600;
}
.rank-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin: 8px 0 60px;
}
.cf-actions {
  display: flex;
  gap: 10px;
}
</style>
