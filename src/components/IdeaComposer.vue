<script setup lang="ts">
import { ref } from 'vue'
import CategoryChips from './CategoryChips.vue'
import { useIdeas } from '@/stores/ideas'
import { useToasts } from '@/stores/toasts'
import type { Category } from '@/catalog'

const ideas = useIdeas()
const { toast } = useToasts()

const title = ref('')
const description = ref('')
const category = ref<Category>('AI')
const customLabel = ref('')
const anonymous = ref(false)
const busy = ref(false)

async function submit() {
  if (title.value.trim().length < 4) {
    toast('Дайте идее название')
    return
  }
  busy.value = true
  const ok = await ideas.submit({
    title: title.value.trim(),
    description: description.value.trim() || 'Без описания',
    category: category.value,
    // Своя тема живёт только у «Другого» (§4.5)
    custom_label: category.value === 'OTHER' ? customLabel.value.trim() || null : null,
    is_anonymous: anonymous.value,
  })
  busy.value = false
  if (!ok) return
  title.value = ''
  description.value = ''
  customLabel.value = ''
  anonymous.value = false
}
</script>

<template>
  <div class="composer">
    <div class="ctop">
      <span class="ic">✦</span>
      <div>
        <h3>Предложить идею</h3>
        <small>Коротко и по делу — детали обсудим уже в командах</small>
      </div>
    </div>
    <div class="c-grid">
      <input
        v-model="title"
        class="inp"
        placeholder="Название идеи — например «Бот-дежурный по инцидентам»"
        maxlength="80"
        aria-label="Название идеи"
      />
      <textarea
        v-model="description"
        class="inp"
        placeholder="В двух-трёх предложениях: какую проблему решаем и зачем"
        maxlength="280"
        aria-label="Описание идеи"
      ></textarea>
      <div>
        <div class="clabel">Категория</div>
        <CategoryChips v-model="category" />
        <input
          v-if="category === 'OTHER'"
          v-model="customLabel"
          class="inp"
          style="margin-top: 10px"
          maxlength="30"
          placeholder="Своя тема одним-двумя словами (необязательно)"
          aria-label="Своя тема"
        />
      </div>
      <div class="c-actions">
        <button class="primary" :disabled="busy" @click="submit">Отправить в облако</button>
        <span class="note">
          Аноним
          <input
            v-model="anonymous"
            type="checkbox"
            style="vertical-align: middle"
            aria-label="Опубликовать анонимно"
          />
          — коллеги не увидят имя, организаторы увидят
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.composer {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  padding: 22px;
  margin-top: 26px;
}
.composer .ctop {
  display: flex;
  align-items: center;
  gap: 11px;
  margin-bottom: 16px;
}
.composer .ctop .ic {
  width: 34px;
  height: 34px;
  border-radius: 9px;
  display: grid;
  place-items: center;
  flex: none;
  background: var(--accent);
  color: var(--accent-ink);
}
.composer .ctop h3 {
  margin: 0;
  font-size: 17px;
  font-weight: 800;
}
.composer .ctop small {
  color: var(--text-faint);
  font-size: 12.5px;
}
.c-grid {
  display: grid;
  gap: 12px;
}
.clabel {
  font-size: 12px;
  color: var(--text-faint);
  margin-bottom: 9px;
}
.c-actions {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-top: 4px;
  flex-wrap: wrap;
}
.c-actions .note {
  font-size: 12.5px;
  color: var(--text-faint);
}
</style>
