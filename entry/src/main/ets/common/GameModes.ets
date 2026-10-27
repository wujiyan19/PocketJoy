/** Modes keep their original rule IDs and archived scores under one public entry. */
export const MATH_MODES: string[] = ['arithmetic', 'compare', 'sequence', 'binary', 'targetsum'];
export const RHYTHM_MODES: string[] = ['rhythm', 'beatjump'];
export const MERGED_GAME_IDS: string[] = ['compare', 'sequence', 'binary', 'targetsum', 'beatjump'];
export function gameEntryForMode(id: string): string {
  if (MATH_MODES.includes(id)) { return 'arithmetic'; }
  return id === 'beatjump' ? 'rhythm' : id;
}
export function modesForGame(id: string): string[] {
  return id === 'arithmetic' ? MATH_MODES.slice() : id === 'rhythm' ? RHYTHM_MODES.slice() : [id];
}
export function hasDifficultyRules(id: string): boolean {
  return !['fruitmerge', 'solitaire', 'spider', 'freecell', 'melody'].includes(id);
}
