import { Context } from '@kit.AbilityKit';
import { intl } from '@kit.LocalizationKit';
import { GAME_CATEGORIES, GameInfo } from '../../common/GameConstants';
import { resolveString } from '../../common/I18nUtils';

const PINYIN_COLLATOR: intl.Collator = new intl.Collator('zh-CN', { usage: 'sort', collation: 'pinyin' });
const NEW_GAME_IDS: string[] = ['fruitslice', 'xiangqi', 'melody', 'screwout', 'blackhole', 'drift', 'buscolor', 'picturepuzzle'];

interface SearchEntry {
  game: GameInfo;
  name: string;
  nameLower: string;
  descriptionLower: string;
}

/** 首页每次取到新的公开目录时，按当前显示语言建立可复用的筛选数据。 */
export class HomeCatalog {
  private entries: SearchEntry[] = [];
  categoryCounts: number[] = new Array<number>(GAME_CATEGORIES.length).fill(0);
  featured: GameInfo[] = [];
  total: number = 0;

  constructor(games: GameInfo[] = [], context?: Context) {
    this.total = games.length;
    for (const game of games) {
      const name: string = resolveString(game.name, context);
      this.entries.push({ game: game, name: name, nameLower: name.toLowerCase(),
        descriptionLower: resolveString(game.description, context).toLowerCase() });
      this.categoryCounts[GAME_CATEGORIES.indexOf(game.category)]++;
      if (NEW_GAME_IDS.includes(game.id)) { this.featured.push(game); }
    }
    this.entries.sort((left: SearchEntry, right: SearchEntry): number => PINYIN_COLLATOR.compare(left.name, right.name));
  }

  search(category: number, text: string): GameInfo[] {
    const keyword: string = text.trim().toLowerCase();
    return this.entries.filter((entry: SearchEntry): boolean =>
      (category === -1 || entry.game.category === GAME_CATEGORIES[category]) &&
      (entry.nameLower.includes(keyword) || entry.descriptionLower.includes(keyword)))
      .map((entry: SearchEntry): GameInfo => entry.game);
  }
}
