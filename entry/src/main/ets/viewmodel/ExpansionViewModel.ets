import { ChessDataIndex } from '../model/game/ExpansionStateCodes';
import { GameDifficulty } from '../common/GameConstants';
import { GameLifecycleBus, GameLifecycleObserver } from '../common/GameLifecycleBus';
import { FrameLoop } from '../common/FrameLoop';
import { GameDataManager } from '../model/GameData';
import { ExpansionModel } from '../model/game/ExpansionModel';
import { SOKOBAN_LEVELS } from '../model/game/SokobanLevels';
import { ExpansionPiece, ExpansionState, sameExpansionState, snapshotExpansion } from '../model/game/ExpansionState';
import { CHESS_IDS } from '../model/game/ExpansionChess';
import { ExpansionRenderPiece } from './ExpansionRenderPiece';
import { ChessPieceMove, chessMovesBetween } from './ChessPieceMove';
import { COMPUTER_GAME_IDS, COMPUTER_TURN_DELAY_MS } from '../common/ComputerOpponent';
import { GameSoundEvent, gameSound } from '../common/GameSound';
import { modesForGame, hasDifficultyRules } from '../common/GameModes';

interface ExpansionSnapshot { version: number; state: ExpansionState; recorded: boolean; paused: boolean; }

@ObservedV2
export class ExpansionViewModel implements GameLifecycleObserver {
  @Trace state: ExpansionState = new ExpansionState();
  @Trace worldPieces: ExpansionRenderPiece[] = [];
  @Trace difficulty: GameDifficulty = GameDifficulty.NORMAL;
  @Trace paused: boolean = false;
  @Trace confirmExit: boolean = false;
  @Trace isFinished: boolean = false;
  @Trace canUndo: boolean = false;
  @Trace puzzleStuck: boolean = false;
  @Trace dragging: boolean = false;
  @Trace legalTargets: number[] = [];
  @Trace feedbackSerial: number = 0;
  @Trace feedbackKind: number = 0;
  @Trace feedbackGain: number = 0;
  @Trace effectsEnabled: boolean = true;
  @Trace computerThinking: boolean = false;
  @Trace computerPlayer: number = 1;
  @Trace chessMoves: ChessPieceMove[] = [];
  @Trace chessBoardBefore: number[] = [];
  @Trace chessAnimationSerial: number = 0;
  @Trace chessAnimating: boolean = false;
  @Trace modeId: string = '';
  @Trace modeHighScore: number = 0;
  @Trace sokobanLevel: number = 0;
  @Trace sokobanCompleted: number = 0;
  private model: ExpansionModel = new ExpansionModel();
  private frame: FrameLoop | null = null;
  private id: string = '';
  private initialState: ExpansionState | null = null;
  private recorded: boolean = false;
  private visible: boolean = true;
  private accumulator: number = 0;
  private tone: (note: number) => void = (note: number): void => {};
  private toneStop: () => void = (): void => {};
  private toneSerial: number = 0;
  private computerTimer: number = -1;
  private computerGeneration: number = 0;

  init(id: string, frame: FrameLoop | null = null): void {
    this.id = id; this.frame = frame; this.difficulty = GameDataManager.getInitialDifficulty(id);
    const mode: string = GameDataManager.getTextSetting('mode_' + id, id);
    this.modeId = modesForGame(id).includes(mode) ? mode : id;
    this.sokobanLevel = 0;
    if (id === 'sokoban') {
      this.sokobanCompleted = Math.min(GameDataManager.getModeScore(id, 'campaign'), SOKOBAN_LEVELS.length);
      this.sokobanLevel = GameDataManager.getTextSetting('sokobanMode', 'campaign') === 'random' ? 0 : this.sokobanUnlocked();
    }
    this.model.deferComputerTurns = true;
  }
  sokobanUnlocked(): number { return Math.min(this.sokobanCompleted + 1, SOKOBAN_LEVELS.length); }
  private rememberSokobanCompleted(completed: number): void {
    if (completed > this.sokobanCompleted) {
      this.sokobanCompleted = completed;
      GameDataManager.recordMode(this.id, 'campaign', completed);
      GameDataManager.flushNow();
    }
  }
  selectSokobanLevel(level: number): void {
    if (this.id !== 'sokoban' || !Number.isInteger(level) || level < 0 || level > this.sokobanUnlocked() || level === this.sokobanLevel) { return; }
    this.sokobanLevel = level;
    GameDataManager.setTextSetting('sokobanMode', level === 0 ? 'random' : 'campaign');
    this.startGame();
  }
  changeMode(mode: string): void {
    if (!modesForGame(this.id).includes(mode) || mode === this.modeId) { return; }
    this.modeId = mode; GameDataManager.setTextSetting('mode_' + this.id, mode); this.startGame();
  }
  setToneCallbacks(play: (note: number) => void, stop: () => void): void { this.tone = play; this.toneStop = stop; this.toneSerial = 0; }
  startGame(): void {
    GameLifecycleBus.selectSoundMode(this, this.modeId);
    this.resetChessAnimation();
    this.stop(); this.paused = false; this.confirmExit = false; this.recorded = false; this.dragging = false;
    this.feedbackKind = 0; this.feedbackGain = 0; this.feedbackSerial++;
    const level: number = this.difficulty === GameDifficulty.EASY ? 0 : this.difficulty === GameDifficulty.HARD ? 2 : 1;
    this.effectsEnabled = this.visible && !this.confirmExit;
    if (this.sokobanLevel > 0) { this.model.startSokobanLevel(this.sokobanLevel); }
    else { this.model.start(this.modeId, level); }
    GameDataManager.recordGameStarted(this.id); this.sync(false);
    this.initialState = this.state;
  }
  changeDifficulty(d: GameDifficulty): void {
    if (d === this.difficulty || this.sokobanLevel > 0) { return; } this.difficulty = d;
    GameDataManager.rememberGameDifficulty(this.id, d); this.startGame();
  }
  private sync(feedback: boolean = true, interaction: boolean = false): void {
    const previous: ExpansionState = this.state;
    this.state = snapshotExpansion(this.model.state, previous); this.canUndo = this.model.canUndo();
    this.puzzleStuck = this.state.outcome === 0 && ((this.id === 'watersort' && !this.model.puzzle.hasWaterMove(this.state)) ||
      (this.id === 'mahjongsolitaire' && !this.model.matching.canContinueMahjong(this.state)));
    this.syncChessAnimation(previous, feedback);
    if (previous.pieces !== this.state.pieces) { this.syncWorldPieces(); }
    this.isFinished = this.state.outcome !== 0;
    const recordId: string = this.modeId === 'picturepuzzle' ? this.modeId + '_' + (this.state.variant ?? 0) : this.modeId;
    this.modeHighScore = GameDataManager.getModeScore(recordId, hasDifficultyRules(this.modeId) ? this.difficulty : 'standard');
    if (feedback && this.effectsEnabled && previous.id === this.state.id && previous.outcome === 0) {
      const gain: number = this.state.score - previous.score;
      const hurt: boolean = ['shooter', 'tanks', 'fortress', 'survival', 'roomdefense'].includes(this.id) &&
        previous.data.length > 0 && this.state.data.length > 0 && this.state.data[this.id === 'roomdefense' ? 1 : 0] < previous.data[this.id === 'roomdefense' ? 1 : 0];
      if (this.state.errors > previous.errors || hurt) { this.feedbackKind = 2; this.feedbackGain = 0; this.feedbackSerial++; }
      else if (gain > 0) { this.feedbackKind = 1; this.feedbackGain = gain; this.feedbackSerial++; }
      if (this.state.outcome !== 0) {
        gameSound.play(this.modeId, this.isDraw() ? GameSoundEvent.DRAW : this.state.outcome === 1 ? GameSoundEvent.WIN : GameSoundEvent.LOSE);
      } else if (this.state.errors > previous.errors || hurt) { gameSound.play(this.modeId, GameSoundEvent.ERROR); }
      else if (gain > 0) { gameSound.play(this.modeId, GameSoundEvent.REWARD); }
      else if (interaction && this.id !== 'melody' && (this.state.moves !== previous.moves || this.state.selected !== previous.selected ||
        this.state.phase !== previous.phase || this.state.cursor !== previous.cursor || this.state.serial !== previous.serial ||
        this.state.next !== previous.next || this.state.pieces.length !== previous.pieces.length || this.state.tray.join(',') !== previous.tray.join(','))) {
        gameSound.play(this.modeId);
      }
    }
    if (this.state.id === 'melody' && this.state.data[1] !== this.toneSerial) {
      this.toneSerial = this.state.data[1]; if (!this.blocked() && this.state.phase === 1 && this.state.selected >= 0) { this.tone(this.state.selected); }
    }
    this.legalTargets = [];
    if (CHESS_IDS.includes(this.state.id) && this.state.selected >= 0) {
      for (let to: number = 0; to < this.state.board.length; to++) { if (this.model.chess.legal(this.model.state, this.state.selected, to)) { this.legalTargets.push(to); } }
    }
    if (this.sokobanLevel > 0) {
      // An in-flight continuation also brings the progress needed to reach that level.
      const completed: number = this.state.outcome === 1 ? this.sokobanLevel : this.sokobanLevel - 1;
      this.rememberSokobanCompleted(completed);
      this.recorded = this.state.outcome !== 0;
    } else if (this.state.outcome !== 0 && !this.recorded) {
      this.recorded = true; this.stop(); GameDataManager.updateHighScore(this.id, this.state.score);
      GameDataManager.recordMode(recordId, hasDifficultyRules(this.modeId) ? this.difficulty : 'standard', this.state.score);
      this.modeHighScore = GameDataManager.getModeScore(recordId, hasDifficultyRules(this.modeId) ? this.difficulty : 'standard');
    }
    if (this.state.outcome !== 0) { this.effectsEnabled = false; }
    this.refreshComputerTurn();
  }
  private syncWorldPieces(): void {
    // ForEach keeps children for the same ID. Update the observed wrapper so their
    // images and transforms read the new snapshot without rebuilding every frame.
    const pieces: ExpansionPiece[] = this.state.pieces;
    if (pieces.length === this.worldPieces.length && pieces.every((p: ExpansionPiece, i: number) => p.alive && p.id === this.worldPieces[i].id)) {
      for (let i: number = 0; i < pieces.length; i++) {
        if (this.worldPieces[i].piece !== pieces[i]) { this.worldPieces[i].piece = pieces[i]; }
      }
      return;
    }
    const existing: Map<number, ExpansionRenderPiece> = new Map<number, ExpansionRenderPiece>();
    this.worldPieces.forEach((rendered: ExpansionRenderPiece) => { existing.set(rendered.id, rendered); });
    const next: ExpansionRenderPiece[] = [];
    this.state.pieces.forEach((piece: ExpansionPiece) => {
      if (!piece.alive) { return; }
      const rendered: ExpansionRenderPiece | undefined = existing.get(piece.id);
      if (rendered) { rendered.piece = piece; next.push(rendered); }
      else { next.push(new ExpansionRenderPiece(piece)); }
    });
    this.worldPieces = next;
  }
  private syncChessAnimation(previous: ExpansionState, feedback: boolean): void {
    if (!CHESS_IDS.includes(this.id)) { return; }
    if (!feedback || this.blocked()) { this.resetChessAnimation(); return; }
    if (this.state.moves === previous.moves) { return; }
    this.resetChessAnimation();
    const moves: ChessPieceMove[] = chessMovesBetween(previous, this.state);
    if (moves.length === 0) { return; }
    this.chessBoardBefore = previous.board.slice(); this.chessMoves = moves; this.chessAnimating = true;
  }
  private resetChessAnimation(): void {
    this.chessAnimationSerial++; this.chessAnimating = false; this.chessMoves = []; this.chessBoardBefore = [];
  }
  finishChessAnimation(serial: number): void {
    if (serial !== this.chessAnimationSerial || !this.chessAnimating) { return; }
    this.resetChessAnimation(); this.refreshComputerTurn();
  }
  tap(index: number): void {
    if (this.chessAnimating || this.computerThinking || this.blocked()) { return; }
    if (this.puzzleStuck && (this.id === 'watersort' || !this.model.matching.canContinueMahjong(this.state))) { return; }
    if (this.state.id === 'melody' && this.state.phase === 0 && this.state.outcome === 0 && index >= 0 && index < 4) { this.tone(index); }
    this.model.tap(index); this.sync(true, true); this.run();
  }
  activate(): void { if (this.blocked()) { return; } this.model.activate(); this.sync(true, true); this.run(); }
  action(): void {
    if (this.blocked()) { return; }
    const completed: boolean = this.model.action(); this.sync(true, true);
    if (!completed && this.id === 'mahjongsolitaire' && this.state.outcome === 0) { this.puzzleStuck = true; }
  }
  choose(index: number): void { if (this.chessAnimating || this.computerThinking || this.blocked()) { return; } this.model.choose(index); this.sync(true, true); }
  undo(): void {
    if (this.blocked() || !this.model.canUndo()) { return; }
    this.cancelComputerTurn(); this.model.undo(); this.recorded = false;
    this.feedbackKind = 0; this.feedbackGain = 0; this.feedbackSerial++; this.sync(false);
  }
  aim(x: number, y: number): void {
    if (this.blocked()) { return; } this.model.aim(x, y); this.sync(true, true); this.run();
  }
  private blocked(): boolean { return this.paused || this.confirmExit || !this.visible; }
  setDragging(active: boolean): void {
    this.dragging = active && !this.blocked();
    if (this.dragging && this.state.id === 'fruitslice') { this.model.releaseControls(); }
    if (!active && this.state.id === 'untangle') { this.model.releaseNode(); this.sync(); }
    if (!active && ['platformer', 'fruitslice', 'hillclimb', 'airhockey', 'fishing'].includes(this.state.id)) { this.model.releaseControls(); this.sync(); }
  }
  terrain(x: number): number { return this.model.sports.terrain(x, this.model.state); }
  mahjongCan(command: number): boolean { return this.model.cards.mahjongCan(this.state, command); }
  tileFree(id: number): boolean { return this.model.matching.tileFree(this.state, id); }
  crossingEdges(): number[] { return this.model.sorting.crossingEdges(this.state); }
  realtime(): boolean { return this.model.realtime(); }
  isDraw(): boolean {
    return this.state.outcome === 1 && (CHESS_IDS.includes(this.state.id) && this.state.data[ChessDataIndex.Draw] === 1 ||
      this.state.id === 'mahjong' && this.state.data[3] === 1);
  }
  top(index: number): number { return this.model.puzzle.top(this.state, index); }
  bubbleX(index: number): number { return this.model.physics.bubbleX(index); }
  bubbleY(index: number): number { return this.model.physics.bubbleY(index); }
  private run(): void {
    if (!this.frame || this.blocked() || this.state.outcome !== 0 || this.model.state.phase === 0) { return; }
    this.frame.start((deltaMs: number) => { this.advance(deltaMs); });
  }
  advance(deltaMs: number): void {
    if (this.blocked() || this.state.outcome !== 0 || !Number.isFinite(deltaMs) || deltaMs < 0) { return; }
    this.accumulator += Math.min(100, deltaMs);
    if (this.accumulator < 8 && this.model.state.phase !== 0 && this.model.state.outcome === 0) { return; }
    while (this.accumulator >= 8 && this.model.state.outcome === 0) { this.model.step(0.008); this.accumulator -= 8; }
    this.sync();
    if (this.model.state.phase === 0 || this.model.state.outcome !== 0) { this.stop(); }
  }
  private stop(): void { this.cancelComputerTurn(); this.frame?.stop(); this.accumulator = 0; this.toneStop(); }
  togglePause(): void {
    this.resetChessAnimation();
    gameSound.stop(this.modeId); this.paused = !this.paused; this.effectsEnabled = !this.blocked() && this.state.outcome === 0; this.setDragging(false); if (this.paused) { this.stop(); } else { this.run(); this.refreshComputerTurn(); } }
  onAppHidden(): void {
    gameSound.stop(this.modeId);
    this.resetChessAnimation();
    this.visible = false; this.effectsEnabled = false; this.setDragging(false); this.stop();
  }
  onAppShown(): void { this.visible = true; this.effectsEnabled = !this.blocked() && this.state.outcome === 0; this.run(); this.refreshComputerTurn(); }
  onBackRequested(): boolean { return this.requestBack(); }
  requestBack(): boolean {
    if (this.state.outcome !== 0 || !GameDataManager.getSetting('confirmExitEnabled', true)) { return false; }
    gameSound.stop(this.modeId); this.resetChessAnimation(); this.confirmExit = true; this.effectsEnabled = false; this.setDragging(false); this.stop(); return true;
  }
  dismissExitConfirm(): void { this.confirmExit = false; this.effectsEnabled = !this.blocked() && this.state.outcome === 0; this.run(); this.refreshComputerTurn(); }
  dispose(): void { this.visible = false; this.effectsEnabled = false; this.resetChessAnimation(); this.stop(); this.setDragging(false); this.frame?.dispose(); }
  isPlayTimeActive(): boolean {
    return this.state.id.length > 0 && this.state.outcome === 0 && !this.paused && !this.confirmExit;
  }

  hasProgress(): boolean {
    if (this.id === 'sokoban') { return this.state.outcome === 0 && this.state.moves > 0; }
    return this.state.outcome === 0 && (!this.initialState || !sameExpansionState(this.state, this.initialState));
  }

  hasComputerOpponent(): boolean { return COMPUTER_GAME_IDS.includes(this.id); }
  private cancelComputerTurn(): void {
    this.computerGeneration++;
    if (this.computerTimer >= 0) { clearTimeout(this.computerTimer); this.computerTimer = -1; }
  }
  private refreshComputerTurn(): void {
    this.computerThinking = this.model.needsComputerTurn();
    this.computerPlayer = this.model.computerPlayer();
    if (!this.computerThinking) { this.cancelComputerTurn(); return; }
    if (this.chessAnimating || this.computerTimer >= 0 || this.blocked() || !GameLifecycleBus.isAppForeground()) { return; }
    const generation: number = this.computerGeneration;
    this.computerTimer = setTimeout(() => {
      if (generation !== this.computerGeneration) { return; }
      this.computerTimer = -1;
      if (this.blocked() || !GameLifecycleBus.isAppForeground() || !this.model.needsComputerTurn()) { return; }
      this.model.computerTurn(); this.sync(true, true);
    }, COMPUTER_TURN_DELAY_MS);
  }

  continuationGameId(): string { return this.id; }
  exportContinuation(): string {
    // Use the live model, including the physics steps since the last rendered frame.
    const snapshot: ExpansionSnapshot = { version: 1, state: this.model.state, recorded: this.recorded, paused: this.paused };
    return JSON.stringify(snapshot);
  }
  importContinuation(payload: string): boolean {
    try {
      if (payload.length > 65536) { return false; }
      const snapshot: ExpansionSnapshot = JSON.parse(payload) as ExpansionSnapshot;
      if (snapshot === null || snapshot.version !== 1 || typeof snapshot.recorded !== 'boolean' || typeof snapshot.paused !== 'boolean') { return false; }
      if (snapshot.state === null || !modesForGame(this.id).includes(snapshot.state.id)) { return false; }
      const expected: ExpansionModel = new ExpansionModel(); expected.start(snapshot.state.id, 1);
      if (!expected.valid(snapshot.state)) { return false; }
      this.modeId = snapshot.state.id;
      GameLifecycleBus.selectSoundMode(this, this.modeId);
      this.stop(); this.model.restore(snapshot.state); this.recorded = snapshot.recorded || snapshot.state.outcome !== 0;
      this.sokobanLevel = this.id === 'sokoban' ? this.model.state.sokobanLevel ?? 0 : 0;
      if (this.sokobanLevel > 0 && snapshot.state.sokobanLevel !== undefined && snapshot.state.outcome === 1 && this.model.state.outcome === 0) {
        this.rememberSokobanCompleted(snapshot.state.sokobanLevel);
      }
      if (this.sokobanLevel === 0) {
        this.difficulty = snapshot.state.level === 0 ? GameDifficulty.EASY : snapshot.state.level === 2 ? GameDifficulty.HARD : GameDifficulty.NORMAL;
      }
      this.paused = snapshot.paused || (this.model.realtime() && snapshot.state.phase !== 0);
      this.confirmExit = false; this.dragging = false; this.effectsEnabled = !this.blocked();
      this.feedbackKind = 0; this.feedbackGain = 0; this.feedbackSerial++; this.sync(false); return true;
    } catch (e) { return false; }
  }
}
