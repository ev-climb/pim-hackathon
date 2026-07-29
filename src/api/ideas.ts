import { supabase } from './supabase'
import type { Category } from '@/catalog'

export type IdeaPublic = {
  id: string
  title: string
  description: string
  category: Category
  custom_label: string | null
  created_at: string
  edited_at: string | null
  author_name: string | null
  vote_count: number
  join_count: number
  comment_count: number
  has_voted: boolean
  has_joined: boolean
  is_mine: boolean
  is_anonymous: boolean
  can_delete: boolean
}

export type CommentPublic = {
  id: string
  idea_id: string
  text: string
  created_at: string
  author_name: string
}

export type NewIdea = {
  title: string
  description: string
  category: Category
  custom_label: string | null
  is_anonymous: boolean
}

const message = (e: unknown) => String((e as { message?: string })?.message ?? '')

/** База отдаёт 'VOTE_BUDGET_EXCEEDED' из триггера app.vote_budget(). */
export const isBudgetError = (e: unknown) => message(e).includes('VOTE_BUDGET_EXCEEDED')

/**
 * 42501 — нарушение политики: так выглядит попытка записи из заблокированного
 * аккаунта. 'FORBIDDEN' — то же самое, но из update_my_idea/delete_my_idea:
 * функции проверяют блокировку сами, до политик дело не доходит.
 */
export const isForbiddenError = (e: unknown) =>
  (e as { code?: string })?.code === '42501' || message(e).includes('FORBIDDEN')

/** delete_my_idea(): на идею уже откликнулись коллеги, удалять поздно. */
export const isReactionsError = (e: unknown) => message(e).includes('IDEA_HAS_REACTIONS')

export async function fetchIdeas(): Promise<IdeaPublic[]> {
  const { data, error } = await supabase
    .from('ideas_public')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data as IdeaPublic[]
}

// Без .select(): сотруднику insert разрешён, а select по политике i_admin — нет,
// поэтому returning упал бы на RLS. Список перечитываем отдельным запросом.
export async function createIdea(idea: NewIdea, authorId: string) {
  const { error } = await supabase.from('ideas').insert({ ...idea, author_id: authorId })
  if (error) throw error
}

// Правка и удаление — через функции: колоночного гранта на ideas у автора нет,
// иначе вместе с текстом он получил бы status и hidden (§3.4).
export async function updateIdea(ideaId: string, idea: NewIdea) {
  const { error } = await supabase.rpc('update_my_idea', {
    target: ideaId,
    new_title: idea.title,
    new_description: idea.description,
    new_category: idea.category,
    new_custom_label: idea.custom_label,
    new_is_anonymous: idea.is_anonymous,
  })
  if (error) throw error
}

export async function deleteIdea(ideaId: string) {
  const { error } = await supabase.rpc('delete_my_idea', { target: ideaId })
  if (error) throw error
}

export async function addVote(ideaId: string, userId: string) {
  const { error } = await supabase.from('votes').insert({ idea_id: ideaId, user_id: userId })
  if (error) throw error
}

export async function removeVote(ideaId: string, userId: string) {
  const { error } = await supabase
    .from('votes')
    .delete()
    .eq('idea_id', ideaId)
    .eq('user_id', userId)
  if (error) throw error
}

export async function addJoin(ideaId: string, userId: string) {
  const { error } = await supabase.from('joins').insert({ idea_id: ideaId, user_id: userId })
  if (error) throw error
}

export async function removeJoin(ideaId: string, userId: string) {
  const { error } = await supabase
    .from('joins')
    .delete()
    .eq('idea_id', ideaId)
    .eq('user_id', userId)
  if (error) throw error
}

export async function fetchComments(ideaId: string): Promise<CommentPublic[]> {
  const { data, error } = await supabase
    .from('comments_public')
    .select('*')
    .eq('idea_id', ideaId)
    .order('created_at', { ascending: true })
  if (error) throw error
  return data as CommentPublic[]
}

export async function addComment(ideaId: string, userId: string, text: string) {
  const { error } = await supabase
    .from('comments')
    .insert({ idea_id: ideaId, user_id: userId, text })
  if (error) throw error
}
