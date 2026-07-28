import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import {
  fetchAdminData,
  setBlocked,
  setHidden,
  setStatus,
  type AdminComment,
  type AdminIdea,
  type Link,
  type Profile,
} from '@/api/admin'
import { categoryOf, type IdeaStatus } from '@/catalog'
import { useToasts } from './toasts'

export type Person = { id: string; name: string; email: string }

export type RankIdea = AdminIdea & {
  authorName: string
  authorEmail: string
  authorBlocked: boolean
  voters: Person[]
  joiners: Person[]
  discussion: (AdminComment & { authorName: string; authorEmail: string })[]
}

type AdminSort = 'likes' | 'joins' | 'cmts' | 'new'

export const useAdmin = defineStore('admin', () => {
  const { toast } = useToasts()

  const ideas = ref<AdminIdea[]>([])
  const profiles = ref<Profile[]>([])
  const votes = ref<Link[]>([])
  const joins = ref<Link[]>([])
  const comments = ref<AdminComment[]>([])
  const loading = ref(false)

  const search = ref('')
  const category = ref('all')
  const sort = ref<AdminSort>('likes')
  const openRow = ref<string | null>(null)

  const byId = computed(() => new Map(profiles.value.map((p) => [p.id, p])))

  function person(id: string): Person {
    const p = byId.value.get(id)
    return { id, name: p?.display_name ?? '—', email: p?.email ?? '—' }
  }

  /** Собираем строки рейтинга: идея + автор с почтой + поимённые списки. */
  const rows = computed<RankIdea[]>(() =>
    ideas.value.map((i) => {
      const author = person(i.author_id)
      return {
        ...i,
        authorName: author.name,
        authorEmail: author.email,
        authorBlocked: byId.value.get(i.author_id)?.blocked ?? false,
        voters: votes.value.filter((v) => v.idea_id === i.id).map((v) => person(v.user_id)),
        joiners: joins.value.filter((j) => j.idea_id === i.id).map((j) => person(j.user_id)),
        discussion: comments.value
          .filter((c) => c.idea_id === i.id)
          .sort((a, b) => +new Date(a.created_at) - +new Date(b.created_at))
          .map((c) => {
            const p = person(c.user_id)
            return { ...c, authorName: p.name, authorEmail: p.email }
          }),
      }
    }),
  )

  const filtered = computed(() => {
    const q = search.value.trim().toLowerCase()
    const list = rows.value.filter((r) => {
      const hay = (
        r.title +
        ' ' +
        r.authorName +
        ' ' +
        r.authorEmail +
        ' ' +
        (r.custom_label ?? '')
      ).toLowerCase()
      return hay.includes(q) && (category.value === 'all' || r.category === category.value)
    })

    const cmp: Record<AdminSort, (a: RankIdea, b: RankIdea) => number> = {
      likes: (a, b) => b.voters.length - a.voters.length,
      joins: (a, b) => b.joiners.length - a.joiners.length,
      cmts: (a, b) => b.discussion.length - a.discussion.length,
      new: (a, b) => +new Date(b.created_at) - +new Date(a.created_at),
    }

    // Скрытые всегда в конце, независимо от выбранной сортировки
    return [...list].sort(cmp[sort.value]).sort((a, b) => Number(a.hidden) - Number(b.hidden))
  })

  const kpi = computed(() => {
    const people = new Set<string>()
    for (const i of ideas.value) people.add(i.author_id)
    for (const v of votes.value) people.add(v.user_id)
    for (const j of joins.value) people.add(j.user_id)
    for (const c of comments.value) people.add(c.user_id)

    const byCat = new Map<string, number>()
    for (const v of votes.value) {
      const idea = ideas.value.find((i) => i.id === v.idea_id)
      if (idea) byCat.set(idea.category, (byCat.get(idea.category) ?? 0) + 1)
    }
    const top = [...byCat.entries()].sort((a, b) => b[1] - a[1])[0]

    return {
      ideas: ideas.value.filter((i) => !i.hidden).length,
      people: people.size,
      votes: votes.value.length,
      topCategory: top ? categoryOf(top[0] as RankIdea['category']).label : '—',
    }
  })

  async function load() {
    loading.value = true
    try {
      const data = await fetchAdminData()
      ideas.value = data.ideas
      profiles.value = data.profiles
      votes.value = data.votes
      joins.value = data.joins
      comments.value = data.comments
    } finally {
      loading.value = false
    }
  }

  function toggleRow(id: string) {
    openRow.value = openRow.value === id ? null : id
  }

  async function changeStatus(id: string, status: IdeaStatus) {
    const idea = ideas.value.find((i) => i.id === id)
    if (!idea) return
    const before = idea.status
    idea.status = status
    try {
      await setStatus(id, status)
      toast('Статус обновлён')
    } catch {
      idea.status = before
      toast('Не получилось изменить статус')
    }
  }

  async function toggleHidden(id: string) {
    const idea = ideas.value.find((i) => i.id === id)
    if (!idea) return
    const next = !idea.hidden
    idea.hidden = next
    try {
      await setHidden(id, next)
      toast(next ? 'Идея скрыта от сотрудников' : 'Идея снова видна')
    } catch {
      idea.hidden = !next
      toast('Не получилось изменить видимость')
    }
  }

  async function toggleBlocked(userId: string) {
    const profile = profiles.value.find((p) => p.id === userId)
    if (!profile) return
    const next = !profile.blocked
    profile.blocked = next
    try {
      await setBlocked(userId, next)
      toast(next ? 'Автор заблокирован' : 'Автор разблокирован')
    } catch {
      profile.blocked = !next
      toast('Не получилось изменить блокировку')
    }
  }

  return {
    loading,
    search,
    category,
    sort,
    openRow,
    rows,
    filtered,
    kpi,
    load,
    toggleRow,
    changeStatus,
    toggleHidden,
    toggleBlocked,
  }
})
