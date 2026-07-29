import { supabase } from './supabase'
import type { Category, IdeaStatus } from '@/catalog'

/** Идея как её видит организатор: с author_id, анонимностью и скрытыми (§3.4). */
export type AdminIdea = {
  id: string
  title: string
  description: string
  category: Category
  custom_label: string | null
  is_anonymous: boolean
  hidden: boolean
  status: IdeaStatus
  author_id: string
  created_at: string
  edited_at: string | null
}

export type Profile = {
  id: string
  email: string
  display_name: string
  blocked: boolean
}

export type Link = { user_id: string; idea_id: string }

export type AdminComment = {
  id: string
  idea_id: string
  user_id: string
  text: string
  created_at: string
}

/** Пять запросов параллельно — джойним на клиенте, отдельных админских вью нет. */
export async function fetchAdminData() {
  const [ideas, profiles, votes, joins, comments] = await Promise.all([
    supabase.from('ideas').select('*'),
    supabase.from('profiles').select('id,email,display_name,blocked'),
    supabase.from('votes').select('user_id,idea_id'),
    supabase.from('joins').select('user_id,idea_id'),
    supabase.from('comments').select('id,idea_id,user_id,text,created_at'),
  ])

  for (const r of [ideas, profiles, votes, joins, comments]) {
    if (r.error) throw r.error
  }

  return {
    ideas: ideas.data as AdminIdea[],
    profiles: profiles.data as Profile[],
    votes: votes.data as Link[],
    joins: joins.data as Link[],
    comments: comments.data as AdminComment[],
  }
}

export async function setStatus(ideaId: string, status: IdeaStatus) {
  const { error } = await supabase.from('ideas').update({ status }).eq('id', ideaId)
  if (error) throw error
}

export async function setHidden(ideaId: string, hidden: boolean) {
  const { error } = await supabase.from('ideas').update({ hidden }).eq('id', ideaId)
  if (error) throw error
}

/** Только через функцию: колонку blocked напрямую не изменить даже организатору. */
export async function setBlocked(userId: string, blocked: boolean) {
  const { error } = await supabase.rpc('set_blocked', { target: userId, val: blocked })
  if (error) throw error
}
