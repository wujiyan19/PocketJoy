/**
 * 滑动拼图 —— ViewModel 层
 *
 * 持有 UI 状态（@ObservedV2 + @Trace），编排规则(Model) + 持久化。
 * 本游戏无暂停玩法：status 只有 进行中 ⇄ 已结束 两态。
 * View 只与它交互，不接触 Model 类型。
 */
import { GameDifficulty, GameStatus } from '../common/GameConstants';
import { ContinuationValidation as V } from '../common/GameSessionTransfer';
import { GameDataManager } from '../model/GameData';
import { GameLifecycleObserver } from '../common/GameLifecycleBus';
import { SlidePuzzleRules } from '../model/game/SlidePuzzleModel';
import { RandomSource, RealRandom } from '../model/game/RandomSource';
import { GameSoundEvent, gameSound } from '../common/GameSound';

const GAME_ID = 'slidepuzzle';


interface SlidePuzzleContinuationState {
  version: number;
  board: number[];
  steps: number;
  best: number;
  difficultyBest?: number;
  unclassifiedScore?: number;
  status: GameStatus;
  difficulty: GameDifficulty;
}

@ObservedV2
export class SlidePuzzleViewModel implements GameLifecycleObserver {
  @Trace board: number[] = [];
  @Trace steps: number = 0;
  @Trace status: GameStatus = GameStatus.PLAYING;
  @Trace best: number = 0;
  @Trace unclassifiedScore: number = 0;
  @Trace difficulty: GameDifficulty = GameDataManager.getInitialDifficulty(GAME_ID);
  /** 退出确认弹窗显隐（F2：对局中返回需确认，防误丢步数进度） */
  @Trace confirmExit: boolean = false;

  private rules: SlidePuzzleRules;
  private rng: RandomSource;

  constructor(rng?: RandomSource) {
    this.rng = rng ?? new RealRandom();
    this.rules = new SlidePuzzleRules(this.getSize());
    this.best = GameDataManager.getBestCount(GAME_ID, this.difficulty);
    this.unclassifiedScore = GameDataManager.getUnclassifiedScore(GAME_ID);
  }

  getSize(): number {
    if (this.difficulty === GameDifficulty.EASY) { return 3; }
    if (this.difficulty === GameDifficulty.HARD) { return 5; }
    return 4;
  }

  changeDifficulty(d: GameDifficulty): void {
    GameDataManager.rememberGameDifficulty(GAME_ID, d);
    if (this.difficulty === d) { return; }
    this.difficulty = d;
    this.startGame();
  }

  startGame(): void {
    gameSound.stop(GAME_ID);
    this.best = GameDataManager.getBestCount(GAME_ID, this.difficulty);
    this.unclassifiedScore = GameDataManager.getUnclassifiedScore(GAME_ID);
    this.rules = new SlidePuzzleRules(this.getSize());
    GameDataManager.recordGameStarted(GAME_ID);
    this.board = this.rules.shuffle(this.rng);
    this.steps = 0;
    this.status = GameStatus.PLAYING;
  }

  cellAt(r: number, c: number): number {
    return this.board[r * this.getSize() + c];
  }

  canMove(r: number, c: number): boolean { return this.rules.canMove(this.board, r, c); }

  tapCell(r: number, c: number): void {
    if (this.status === GameStatus.OVER) { return; }
    if (!this.rules.canMove(this.board, r, c)) { return; }
    this.board = this.rules.tap(this.board, r, c);
    this.steps++;
    gameSound.play(GAME_ID);
    if (this.rules.isSolved(this.board)) {
      gameSound.play(GAME_ID, GameSoundEvent.WIN);
      this.status = GameStatus.OVER;
      GameDataManager.recordBestCount(GAME_ID, this.difficulty, this.steps);
      this.best = GameDataManager.getBestCount(GAME_ID, this.difficulty);
      GameDataManager.updateHighScore(GAME_ID, this.rules.score(this.steps));
    }
  }

  getBestText(): string {
    if (this.best === 0) { return '--'; }
    return '' + this.best;
  }

  // —— GameLifecycleObserver（完成才计分、无定时器：切后台无需暂停/结算）——
  onAppHidden(): void {
    gameSound.stop(GAME_ID);
  }

  onAppShown(): void {
    this.best = GameDataManager.getBestCount(GAME_ID, this.difficulty);
    this.unclassifiedScore = GameDataManager.getUnclassifiedScore(GAME_ID);
  }

  /** 系统侧滑返回转发（NavDestination.onBackPressed）。进行中弹确认并拦截 */
  onBackRequested(): boolean {
    return this.requestBack();
  }

  /** 页面返回按钮与系统侧滑共用：进行中弹确认（进度无保存机制，防误退），其余放行 */
  requestBack(): boolean {
    if (!GameDataManager.getSetting('confirmExitEnabled', true)) { return false; }
    if (this.status === GameStatus.PLAYING) {
      gameSound.stop(GAME_ID); this.confirmExit = true;
      return true;
    }
    return false;
  }

  dismissExitConfirm(): void {
    this.confirmExit = false;
  }

  /** 页面销毁：无定时器可停（保持全部 VM 的 dispose 形态统一） */
  dispose(): void {
  }

  isPlayTimeActive(): boolean { return this.status === GameStatus.PLAYING && !this.confirmExit; }

  hasProgress(): boolean { return this.status !== GameStatus.OVER && this.steps > 0; }

  continuationGameId(): string { return GAME_ID; }

  /** Capture only game data; exporting never pauses or mutates the source game. */
  exportContinuation(): string {

    const state: SlidePuzzleContinuationState = {
      version: 1,
      board: this.board,
      steps: this.steps,
      best: Math.max(1, Math.min(999, 1000 - GameDataManager.archivedModeScore(GAME_ID))),
      difficultyBest: GameDataManager.getBestCount(GAME_ID, this.difficulty),
      unclassifiedScore: GameDataManager.getUnclassifiedScore(GAME_ID),
      status: this.status,
      difficulty: this.difficulty
    };
    return JSON.stringify(state);
  }

  /** Validate completely before replacing a running game. Rebuild observed class instances. */
  importContinuation(payload: string): boolean {
    try {
      if (payload.length > 65536) { return false; }
      const s: SlidePuzzleContinuationState = JSON.parse(payload) as SlidePuzzleContinuationState;
      if (s === null || s.version !== 1 || !V.integer(s.steps) ||
          (s.difficultyBest !== undefined && !V.integer(s.difficultyBest)) ||
          (s.unclassifiedScore !== undefined && !V.integer(s.unclassifiedScore)) ||
          ((s.difficultyBest === undefined) !== (s.unclassifiedScore === undefined)) ||
          !V.integer(s.best) ||
          (s.status !== GameStatus.PLAYING && s.status !== GameStatus.PAUSED && s.status !== GameStatus.OVER && s.status !== GameStatus.IDLE) ||
          (s.difficulty !== GameDifficulty.EASY && s.difficulty !== GameDifficulty.NORMAL && s.difficulty !== GameDifficulty.HARD)) { return false; }
      const size: number = s.difficulty === GameDifficulty.EASY ? 3 : (s.difficulty === GameDifficulty.HARD ? 5 : 4);
      if (!V.numbers(s.board, size * size, 0, size * size - 1) || new Set<number>(s.board).size !== size * size) { return false; }

      this.board = s.board;
      this.steps = s.steps;
      const count: number = s.difficultyBest ?? 0;
      const oldScore: number = s.unclassifiedScore ??
        (s.best > 0 && s.best < 999 ? this.rules.score(s.best) : 0);
      GameDataManager.recordBestCount(GAME_ID, s.difficulty, count, oldScore);
      this.best = GameDataManager.getBestCount(GAME_ID, s.difficulty);
      this.unclassifiedScore = GameDataManager.getUnclassifiedScore(GAME_ID);
      GameDataManager.updateHighScore(GAME_ID, Math.max(oldScore, count > 0 ? this.rules.score(count) : 0));
      this.status = s.status;
      this.difficulty = s.difficulty;
      this.confirmExit = false;
      this.rules = new SlidePuzzleRules(this.getSize());
      return true;
    } catch (e) {
      return false;
    }
  }
}
