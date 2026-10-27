/** 当前单人合集撤下的玩法；保留原模型与资源，便于独立回归和后续恢复。 */
import { MERGED_GAME_IDS } from './GameModes';

const RETIRED_GAME_IDS: string[] = [
  'tictactoe', 'gomoku', 'reversi', 'fourline', 'nim', 'dots', 'tug',
  'doudizhu', 'guandan', 'mahjong', 'ludo',
  'hiddenobjects', 'farm', 'decorate', 'characters', 'idiom',
  'wordtower', 'backpack', 'differences', 'onestroke', 'golf',
  'billiards', 'basketball', 'penalty',
  'jumpjump', 'slotpair', 'missing', 'sand', 'linerescue', 'bowling', 'pipes'
];

/** 上架策略只控制已登记玩法的可见性；未知 ID 仍由目录和路由拒绝。 */
export function isGameAvailable(gameId: string): boolean {
  return !RETIRED_GAME_IDS.includes(gameId) && !MERGED_GAME_IDS.includes(gameId);
}
