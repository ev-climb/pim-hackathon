import { supabase } from './supabase'

export type Me = {
  display_name: string
  is_admin: boolean
  votes_used: number
  vote_budget: number
  blocked: boolean
}

export function signInWithGoogle() {
  return supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: window.location.origin + '/ideas' },
  })
}

export function signOut() {
  return supabase.auth.signOut()
}

export async function getSession() {
  const { data } = await supabase.auth.getSession()
  return data.session
}

export async function getUserId() {
  const session = await getSession()
  return session?.user.id ?? null
}

/** Один вызов на старте приложения: имя, признак админа, потраченные голоса (§5.1). */
export async function fetchMe(): Promise<Me> {
  const { data, error } = await supabase.rpc('me')
  if (error) throw error
  return data as Me
}

export async function renameMe(displayName: string) {
  const id = await getUserId()
  if (!id) throw new Error('NOT_AUTHENTICATED')
  const { error } = await supabase
    .from('profiles')
    .update({ display_name: displayName })
    .eq('id', id)
  if (error) throw error
}
