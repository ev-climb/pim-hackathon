/**
 * Русское склонение по числу: 1 идея, 2 идеи, 5 идей.
 * Формы передаются тройкой [для 1, для 2, для 5] — ноль и всё непонятное
 * уходят в третью, как «0 идей».
 */
export function plural(n: number, forms: readonly [string, string, string]): string {
  const rest = Math.abs(n) % 100
  // Второй десяток — всегда третья форма, иначе получится «11 идея» и «112 идеи»
  if (rest > 10 && rest < 20) return forms[2]
  const last = rest % 10
  if (last === 1) return forms[0]
  if (last > 1 && last < 5) return forms[1]
  return forms[2]
}
