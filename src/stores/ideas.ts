import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import {
  addComment,
  addJoin,
  addVote,
  createIdea,
  deleteIdea,
  fetchComments,
  fetchIdeas,
  isBudgetError,
  isForbiddenError,
  isReactionsError,
  removeJoin,
  removeVote,
  updateIdea,
  type CommentPublic,
  type IdeaPublic,
  type NewIdea,
} from '@/api/ideas'
import { useAuth } from './auth'
import { useToasts } from './toasts'

type Sort = 'new' | 'popular'

export const useIdeas = defineStore('ideas', () => {
  const auth = useAuth()
  const { toast } = useToasts()

  const list = ref<IdeaPublic[]>([])
  const loading = ref(false)
  const filter = ref<string>('all')
  const sort = ref<Sort>('new') // §4.7: «Новые» по умолчанию, иначе поздние идеи никто не увидит
  const comments = ref<CommentPublic[]>([])
  const commentsLoading = ref(false)

  const visible = computed(() => {
    const rows = list.value.filter((i) => filter.value === 'all' || i.category === filter.value)
    return sort.value === 'popular'
      ? [...rows].sort((a, b) => b.vote_count - a.vote_count)
      : [...rows].sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at))
  })

  const votesLeft = computed(() =>
    auth.me ? Math.max(0, auth.me.vote_budget - auth.me.votes_used) : 0,
  )

  async function load() {
    loading.value = true
    try {
      list.value = await fetchIdeas()
    } finally {
      loading.value = false
    }
  }

  /** Общий разбор ошибки записи: заблокированному объясняем, почему кнопка не сработала. */
  function reportWriteError(e: unknown) {
    if (isBudgetError(e)) {
      toast('Голоса закончились. Снимите голос с другой идеи, чтобы отдать его этой')
    } else if (isReactionsError(e)) {
      toast('Идею уже поддержали коллеги — удалить нельзя, но её можно изменить')
    } else if (isForbiddenError(e)) {
      toast('Публикация с вашего аккаунта приостановлена')
    } else {
      toast('Не получилось. Попробуйте ещё раз')
    }
  }

  /** Заблокированному отказываем сразу, без оптимистичного мигания счётчика. */
  function blockedStop() {
    if (!auth.me?.blocked) return false
    toast('Публикация с вашего аккаунта приостановлена')
    return true
  }

  async function toggleVote(id: string) {
    const idea = list.value.find((i) => i.id === id)
    if (!idea || !auth.userId || blockedStop()) return
    const wasVoted = idea.has_voted

    if (!wasVoted && votesLeft.value === 0) {
      toast('Голоса закончились. Снимите голос с другой идеи, чтобы отдать его этой')
      return
    }

    // Оптимистично: счётчик и пилюля бюджета не ждут сервер
    idea.has_voted = !wasVoted
    idea.vote_count += wasVoted ? -1 : 1
    auth.addVotesUsed(wasVoted ? -1 : 1)

    try {
      if (wasVoted) await removeVote(id, auth.userId)
      else await addVote(id, auth.userId)

      if (wasVoted) toast('Голос снят — свободных голосов: ' + votesLeft.value)
      else if (votesLeft.value) toast('Голос учтён. Осталось: ' + votesLeft.value)
      else toast('Голос учтён. Это был последний из 5')
    } catch (e) {
      idea.has_voted = wasVoted
      idea.vote_count += wasVoted ? 1 : -1
      auth.addVotesUsed(wasVoted ? 1 : -1)
      reportWriteError(e)
    }
  }

  async function toggleJoin(id: string) {
    const idea = list.value.find((i) => i.id === id)
    if (!idea || !auth.userId || blockedStop()) return
    const wasJoined = idea.has_joined

    idea.has_joined = !wasJoined
    idea.join_count += wasJoined ? -1 : 1

    try {
      if (wasJoined) await removeJoin(id, auth.userId)
      else {
        await addJoin(id, auth.userId)
        toast('Записали в команду 🙋')
      }
    } catch (e) {
      idea.has_joined = wasJoined
      idea.join_count += wasJoined ? 1 : -1
      reportWriteError(e)
    }
  }

  async function submit(idea: NewIdea) {
    if (!auth.userId) return false
    try {
      await createIdea(idea, auth.userId)
      await load()
      toast('Идея в облаке ✦')
      return true
    } catch (e) {
      reportWriteError(e)
      return false
    }
  }

  async function edit(id: string, idea: NewIdea) {
    if (!auth.userId || blockedStop()) return false
    try {
      await updateIdea(id, idea)
      await load()
      toast('Идея обновлена ✦')
      return true
    } catch (e) {
      reportWriteError(e)
      return false
    }
  }

  async function remove(id: string) {
    const idea = list.value.find((i) => i.id === id)
    if (!idea || !auth.userId || blockedStop()) return false
    try {
      await deleteIdea(id)
      // Свой голос уходит вместе с идеей — возвращаем его в бюджет
      if (idea.has_voted) auth.addVotesUsed(-1)
      list.value = list.value.filter((i) => i.id !== id)
      toast('Идея удалена')
      return true
    } catch (e) {
      reportWriteError(e)
      return false
    }
  }

  async function loadComments(ideaId: string) {
    commentsLoading.value = true
    comments.value = []
    try {
      comments.value = await fetchComments(ideaId)
    } finally {
      commentsLoading.value = false
    }
  }

  async function postComment(ideaId: string, text: string) {
    if (!auth.userId || blockedStop()) return false
    try {
      await addComment(ideaId, auth.userId, text)
      const idea = list.value.find((i) => i.id === ideaId)
      if (idea) idea.comment_count += 1
      await loadComments(ideaId)
      toast('Дополнение добавлено 💬')
      return true
    } catch (e) {
      reportWriteError(e)
      return false
    }
  }

  return {
    list,
    loading,
    filter,
    sort,
    comments,
    commentsLoading,
    visible,
    votesLeft,
    load,
    toggleVote,
    toggleJoin,
    submit,
    edit,
    remove,
    loadComments,
    postComment,
  }
})
