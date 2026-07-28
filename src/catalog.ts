// Единственный словарь значений enum → подпись и цвет. Порядок важен, он же в UI.
export const CATEGORIES = [
  { id: 'AI', label: 'AI-агенты', color: '#F6C915' },
  { id: 'TOOLS', label: 'Внутр. инструменты', color: '#7DD3FC' },
  { id: 'AUTO', label: 'Автоматизация', color: '#A78BFA' },
  { id: 'INTEGR', label: 'Интеграции', color: '#F472B6' },
  { id: 'GAME', label: 'Игровые проекты', color: '#4ADE80' },
  { id: 'EXP', label: 'Эксперименты', color: '#FB923C' },
  { id: 'OTHER', label: 'Другое', color: '#9C9CA6' },
] as const

export type Category = (typeof CATEGORIES)[number]['id']

export const categoryOf = (id: Category) =>
  CATEGORIES.find((c) => c.id === id) ?? CATEGORIES[0]

export const STATUSES = [
  { id: 'REVIEW', label: 'На рассмотрении' },
  { id: 'SELECTED', label: 'В программу' },
  { id: 'RESERVE', label: 'В резерв' },
] as const

export type IdeaStatus = (typeof STATUSES)[number]['id']

export const VOTE_BUDGET = 5
