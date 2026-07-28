<script setup lang="ts">
import { computed } from 'vue'
import { categoryOf, STATUSES, type IdeaStatus } from '@/catalog'
import { ago, initials } from '@/time'
import type { RankIdea } from '@/stores/admin'

const props = defineProps<{ idea: RankIdea; rank: number | null; open: boolean }>()
const emit = defineEmits<{
  toggle: []
  status: [IdeaStatus]
  hide: []
  block: []
}>()

const cat = computed(() => categoryOf(props.idea.category))
const label = computed(() =>
  props.idea.category === 'OTHER' && props.idea.custom_label
    ? 'Другое · ' + props.idea.custom_label
    : cat.value.label,
)
const isTop = computed(() => !props.idea.hidden && props.rank !== null && props.rank <= 3)
</script>

<template>
  <div class="rrow" :class="{ top: isTop, open: props.open, hid: props.idea.hidden }">
    <div class="rmain" @click="emit('toggle')">
      <div class="rank">{{ props.rank ?? '—' }}</div>
      <div class="rinfo">
        <div class="rt">
          {{ props.idea.title }}
          <span class="tag rtag">
            <span class="cc" :style="{ background: cat.color }"></span>{{ label }}
          </span>
        </div>
        <div class="rmeta">
          <span class="mini-av rav">{{ initials(props.idea.authorName) }}</span>
          {{ props.idea.authorName }}
          <span class="mail">{{ props.idea.authorEmail }}</span>
          <span v-if="props.idea.is_anonymous" class="anon-badge">АНОНИМ ДЛЯ КОЛЛЕГ</span>
          <span v-if="props.idea.hidden" class="badge hid">СКРЫТА</span>
          <span v-if="props.idea.authorBlocked" class="badge blocked">АВТОР ЗАБЛОКИРОВАН</span>
        </div>
      </div>

      <div class="stat-pill like">
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path
            d="M7 10v11M2 13v6a2 2 0 002 2h13.3a2 2 0 002-1.6l1.4-7a2 2 0 00-2-2.4H14V6a2.5 2.5 0 00-2.5-2.5L8 12H7"
          />
        </svg>
        {{ props.idea.voters.length }}
      </div>
      <div class="stat-pill join">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
          <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8z" />
        </svg>
        {{ props.idea.joiners.length }}
      </div>
      <div class="stat-pill cmt">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path
            d="M21 11.5a8.4 8.4 0 01-9 8.4 8.5 8.5 0 01-3.8-.9L3 21l1.9-5.2A8.4 8.4 0 013.6 8 8.5 8.5 0 0112 3.5a8.4 8.4 0 019 8z"
          />
        </svg>
        {{ props.idea.discussion.length }}
      </div>

      <select
        class="status-sel"
        :value="props.idea.status"
        aria-label="Статус идеи"
        @click.stop
        @change="emit('status', ($event.target as HTMLSelectElement).value as IdeaStatus)"
      >
        <option v-for="s in STATUSES" :key="s.id" :value="s.id">{{ s.label }}</option>
      </select>

      <svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M6 9l6 6 6-6" />
      </svg>
    </div>

    <div class="rdetail">
      <div class="rdetail-in">
        <div>
          <div class="dl">Отдали голос · {{ props.idea.voters.length }}</div>
          <div class="people">
            <span v-for="p in props.idea.voters" :key="p.id" class="person">
              <span class="mini-av">{{ initials(p.name) }}</span>
              <span>{{ p.name }}<span class="pm">{{ p.email }}</span></span>
            </span>
            <span v-if="!props.idea.voters.length" class="empty-people">Голосов пока нет</span>
          </div>
        </div>
        <div>
          <div class="dl">Готовы в команду · {{ props.idea.joiners.length }}</div>
          <div class="people">
            <span v-for="p in props.idea.joiners" :key="p.id" class="person">
              <span class="mini-av">{{ initials(p.name) }}</span>
              <span>{{ p.name }}<span class="pm">{{ p.email }}</span></span>
            </span>
            <span v-if="!props.idea.joiners.length" class="empty-people">Желающих пока нет</span>
          </div>
        </div>

        <div class="rdesc">{{ props.idea.description }}</div>

        <div class="rcmts">
          <div class="dl">Дополнения · {{ props.idea.discussion.length }}</div>
          <div v-for="c in props.idea.discussion" :key="c.id" class="cmt">
            <span class="mini-av">{{ initials(c.authorName) }}</span>
            <div class="cbody">
              <div class="cname">
                {{ c.authorName }}
                <span class="pm mono">{{ c.authorEmail }}</span>
                <span>{{ ago(c.created_at) }}</span>
              </div>
              <div class="ctext">{{ c.text }}</div>
            </div>
          </div>
          <div v-if="!props.idea.discussion.length" class="empty-people">Дополнений нет</div>
        </div>

        <!-- Кнопки модерации внутри развёрнутой строки: лишний клик здесь полезен (§5.1) -->
        <div class="mod-row">
          <button class="mod" @click="emit('hide')">
            {{ props.idea.hidden ? 'Вернуть идею' : 'Скрыть идею' }}
          </button>
          <button class="mod danger" @click="emit('block')">
            {{ props.idea.authorBlocked ? 'Разблокировать автора' : 'Заблокировать автора' }}
          </button>
          <span class="mod-note">
            {{
              props.idea.hidden
                ? 'Идея не видна сотрудникам, голоса вернулись в их бюджет'
                : 'Скрытую идею можно вернуть в любой момент'
            }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.rrow {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  transition: 0.18s;
}
.rrow:hover {
  border-color: var(--border-strong);
}
.rmain {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 15px 18px;
  cursor: pointer;
}
.rank {
  font-family: 'Archivo Expanded', sans-serif;
  font-weight: 900;
  font-size: 22px;
  width: 40px;
  text-align: center;
  flex: none;
  color: var(--text-faint);
}
.rrow.top .rank {
  color: var(--accent);
}
.rinfo {
  flex: 1;
  min-width: 0;
}
.rinfo .rt {
  font-size: 16px;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 9px;
  flex-wrap: wrap;
}
.rtag {
  font-size: 10px;
  padding: 3px 8px;
  border-radius: 999px;
}
.rtag .cc {
  width: 6px;
  height: 6px;
}
.rinfo .rmeta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
  color: var(--text-faint);
  margin-top: 5px;
  flex-wrap: wrap;
}
.rav {
  width: 20px;
  height: 20px;
  font-size: 10px;
}
.rinfo .rmeta .mail {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11.5px;
  color: var(--text-dim);
}
.anon-badge {
  background: rgba(246, 201, 21, 0.14);
  color: var(--accent);
  border-radius: 6px;
  padding: 2px 7px;
  font-size: 10.5px;
  font-weight: 700;
}
.stat-pill {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 700;
  padding: 6px 11px;
  border-radius: 9px;
  background: var(--surface-2);
  flex: none;
}
.stat-pill svg {
  width: 14px;
  height: 14px;
}
.stat-pill.like {
  color: var(--accent);
}
.stat-pill.join {
  color: var(--good);
}
.stat-pill.cmt {
  color: var(--text-dim);
}
.status-sel {
  border-radius: 8px;
  padding: 7px 10px;
  font-size: 12px;
  font-weight: 700;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--text-dim);
}
.chev {
  width: 18px;
  height: 18px;
  color: var(--text-faint);
  transition: 0.2s;
  flex: none;
}
.rrow.open .chev {
  transform: rotate(180deg);
}
.rdetail {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.35s ease;
}
.rrow.open .rdetail {
  max-height: 1200px;
}
.rdetail-in {
  padding: 0 18px 18px 74px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 22px;
}
@media (max-width: 680px) {
  .rdetail-in {
    grid-template-columns: 1fr;
    padding-left: 18px;
  }
  .rmain {
    flex-wrap: wrap;
  }
  .rank {
    width: auto;
  }
}
.people {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
}
.person {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--surface-2);
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 4px 12px 4px 4px;
  font-size: 12.5px;
}
.person .mini-av {
  width: 22px;
  height: 22px;
  font-size: 10px;
}
.person .pm {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10.5px;
  color: var(--text-faint);
  display: block;
}
.mono {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10.5px;
  color: var(--text-faint);
}
.rdesc {
  grid-column: 1/-1;
  color: var(--text-dim);
  font-size: 14px;
  line-height: 1.55;
  padding-top: 14px;
  border-top: 1px solid var(--border);
}
.rcmts {
  grid-column: 1/-1;
  padding-top: 14px;
  border-top: 1px solid var(--border);
}
.rrow.hid {
  opacity: 0.45;
}
.rrow.hid:hover {
  opacity: 0.75;
}
.badge {
  border-radius: 6px;
  padding: 2px 7px;
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.03em;
}
.badge.hid {
  background: rgba(255, 255, 255, 0.08);
  color: var(--text-dim);
}
.badge.blocked {
  background: rgba(248, 113, 113, 0.14);
  color: #f87171;
}
.mod-row {
  grid-column: 1/-1;
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  padding-top: 14px;
  border-top: 1px solid var(--border);
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
</style>
