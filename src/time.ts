/** Относительное время для дополнений — как в прототипе: «только что», «3 ч назад», «вчера». */
export function ago(iso: string): string {
  const diff = Date.now() - +new Date(iso)
  const min = Math.floor(diff / 60000)
  if (min < 1) return 'только что'
  if (min < 60) return min + ' мин назад'
  const hours = Math.floor(min / 60)
  if (hours < 24) return hours + ' ч назад'
  const days = Math.floor(hours / 24)
  if (days === 1) return 'вчера'
  if (days < 7) return days + ' дн назад'
  return new Date(iso).toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' })
}

export const initials = (name: string) => name.trim()[0]?.toUpperCase() || '?'
