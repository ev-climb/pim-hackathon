import { supabase } from './supabase'
import type { Category } from '@/catalog'

export type IdeaPublic = {
  id: string
  title: string
  description: string
  category: Category
  custom_label: string | null
  created_at: string
  author_name: string | null
  vote_count: number
  join_count: number
  comment_count: number
  has_voted: boolean
  has_joined: boolean
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

/** База отдаёт 'VOTE_BUDGET_EXCEEDED' из триггера app.vote_budget(). */
export const isBudgetError = (e: unknown) =>
  String((e as { message?: string })?.message ?? '').includes('VOTE_BUDGET_EXCEEDED')

/** 42501 — нарушение политики: так выглядит попытка записи из заблокированного аккаунта. */
export const isForbiddenError = (e: unknown) => (e as { code?: string })?.code === '42501'

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
