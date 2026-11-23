import { GameColorCue } from '../../common/GameColorCue';
import { modesForGame, hasDifficultyRules } from '../../common/GameModes';
import { GameModePicker } from '../../components/GameModePicker';
import { SokobanPlayArea } from './SokobanPlayArea';
import { PageDestination } from '../../components/PageDestination';
import { GameInfo, GameDifficulty } from '../../common/GameConstants';
import { SemanticColors, FontTokens, RadiusTokens, SpacingTokens } from '../../common/DesignTokens';
import { SafeAreaInsets, SafeAreaState } from '../../common/SafeAreaInsets';
import { DisplayFrameLoop } from '../../common/DisplayFrameLoop';
import { GameLifecycleBus } from '../../common/GameLifecycleBus';
import { GameSessionTransfer } from '../../common/GameSessionTransfer';
import { GameDataManager } from '../../model/GameData';
import { ExpansionPiece, ExpansionPile, BLOCK_SHAPES } from '../../model/game/ExpansionState';
import { FRUIT_WARNING_Y } from '../../model/game/ExpansionPhysics';
import { isDangerousFish } from '../../model/game/ExpansionAdventure';
import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { Haptics } from '../../common/Haptics';
import { ExpansionRenderPiece } from '../../viewmodel/ExpansionRenderPiece';
import { GameHeader } from '../../components/GameHeader';
import { GameResultDialog } from '../../components/GameResultDialog';
import { ComputerOpponentPanel } from '../../components/ComputerOpponentPanel';
import { ExitConfirmDialog } from '../../components/ExitConfirmDialog';
import { range } from '../../common/Range';
import { ExpansionExtras } from './ExpansionExtras';
import { ExpansionMatchingBoard } from './ExpansionMatchingBoard';
import { ExpansionSortingBoard } from './ExpansionSortingBoard';
import { MATCHING_IDS } from '../../model/game/ExpansionMatching';
import { SORTING_IDS } from '../../model/game/ExpansionSorting';
import { ACTION_IDS } from '../../model/game/ExpansionAction';
import { SPORTS_IDS } from '../../model/game/ExpansionSports';
import { ExpansionWorldBoard } from './ExpansionWorldBoard';
import { ExpansionCardBoard } from './ExpansionCardBoard';
import { CHESS_IDS } from '../../model/game/ExpansionChess';
import { BRAIN_IDS } from '../../model/game/ExpansionBrain';
import { ExpansionBrainBoard } from './ExpansionBrainBoard';
import { ExpansionLifeBoard } from './ExpansionLifeBoard';
import { ExpansionArt } from '../../common/ExpansionArt';
import { ExpansionBackdrop } from './ExpansionBackdrop';
import { GameArtTile } from '../../components/GameArtTile';
import { ExpansionFeedback } from '../../components/ExpansionFeedback';
import { ToyPuzzleBoard } from '../../components/ToyPuzzleBoard';
import { ToyBlackholeStage } from '../../components/ToyBlackholeStage';
import { BlackholeLevels } from '../../model/game/ToyLevelRules';
import { SOKOBAN_LEVELS } from '../../model/game/SokobanLevels';

@ComponentV2
export struct ExpansionPage {
  @Local safeArea: SafeAreaState = SafeAreaInsets.state;
  @Param gameId: string = '';
  @Param pathStack: NavPathStack = new NavPathStack();
  @Local vm: ExpansionViewModel = new ExpansionViewModel();
  @Local game: GameInfo | undefined = undefined;
  @Local arenaWidth: number = 320;
  @Local contentHeight: number = 720;
  private screwControlsReserve: number = 228;
  private screwBoardMinHeight: number = 260;
  private chaseControlsReserve: number = 190;

  @Monitor('vm.isFinished', 'vm.confirmExit', 'vm.paused')
  playTimeStateChanged(): void { GameLifecycleBus.updatePlayTime(this.vm); }

  aboutToAppear(): void {
    const host = this.getUIContext().getHostContext();
    if (host) {
      this.screwControlsReserve = host.resourceManager.getNumber($r('app.float.toy_screw_controls_reserve').id);
      this.screwBoardMinHeight = host.resourceManager.getNumber($r('app.float.toy_screw_board_min_height').id);
      this.chaseControlsReserve = host.resourceManager.getNumber($r('app.float.toy_chase_controls_reserve').id);
    }
    this.game = GameDataManager.getGameById(this.gameId);
    this.vm.init(this.gameId, new DisplayFrameLoop(this.getUIContext())); GameLifecycleBus.attach(this.vm);
    if (!GameSessionTransfer.restore(this.vm)) { this.vm.startGame(); }
    this.playTimeStateChanged();
  }
  aboutToDisappear(): void { GameLifecycleBus.detach(this.vm); this.vm.dispose(); }
  requestExit(): void { if (!this.vm.requestBack()) { this.pathStack.pop(); } }
  color(value: number): Resource {
    const palette: Resource[] = [$r('app.color.expansion_color_1'), $r('app.color.expansion_color_2'), $r('app.color.expansion_color_3'),
      $r('app.color.expansion_color_4'), $r('app.color.expansion_color_5'), $r('app.color.expansion_color_6')];
    return value <= 0 ? SemanticColors.surface : palette[(value - 1) % palette.length];
  }
  symbol(value: number): string { return GameColorCue.symbol(value); }
  arrow(value: number): string { return ['↑', '→', '↓', '←'][value % 4]; }
  arenaRadius(p: ExpansionPiece): number { return p.kind === 8 ? 70 : p.kind === 10 ? 50 : p.r; }
  arenaScale(): number { return this.arenaWidth / 360; }
  measureArena(area: Area): void {
    const width: number = Number(area.width);
    if (Number.isFinite(width) && width > 0) { this.arenaWidth = width; }
  }
  resultTitle(): Resource {
    if (this.vm.isDraw()) { return $r('app.string.expansion_draw_game'); }
    return this.vm.state.outcome === 1 ? $r('app.string.collection_win') : $r('app.string.collection_fail');
  }
  value(index: number): number {
    if (this.gameId === 'tilestack') { const top: number = this.vm.top(index); return top < 0 ? 0 : this.vm.state.board[top]; }
    return this.vm.state.board[index];
  }
  depth(index: number): number {
    const count: number = this.vm.state.cols * this.vm.state.rows; let result: number = 0;
    for (let layer: number = 0; layer < 3; layer++) { if (this.vm.state.board[layer * count + index] > 0) { result++; } } return result;
  }
  cellText(index: number): string {
    const v: number = this.value(index); if (this.gameId === 'arrowclear') { return v === 0 ? '' : this.arrow(v - 1); }
    return this.gameId === 'blockfit' ? '' : this.symbol(v);
  }
  cellArt(index: number): Resource {
    const value: number = this.value(index);
    if (value === 0) { return $r('app.media.exp_empty'); }
    if (this.gameId === 'arrowclear') { return ExpansionArt.arrow(value - 1); }
    return this.gameId === 'blockfit' ? ExpansionArt.block(value - 1) : ExpansionArt.tile(value - 1);
  }
  remaining(): number {
    if (this.gameId === 'solitaire') { return 52 - this.vm.state.piles.slice(9).reduce((total: number, pile: ExpansionPile) => total + pile.cards.length, 0); }
    return this.gameId === 'screwout' || this.gameId === 'parkingjam' || this.gameId === 'mahjongsolitaire' ? this.vm.state.pieces.filter((p: ExpansionPiece) => p.alive && p.kind !== 1).length :
      this.vm.state.board.filter((v: number) => v > 0).length;
  }

  @Builder
  PageHeader() {
    GameHeader({ gameId: this.gameId, rulesModeId: this.vm.modeId, pathStack: this.pathStack, hasProgress: (): boolean => this.vm.hasProgress(), gameTitle: this.vm.modeId === 'beatjump' ? $r('app.string.game_beatjump_name') : this.game?.name ?? '',
          showScore: this.vm.sokobanLevel === 0, scoreValue: this.vm.state.score, subtitle: $r('app.string.sokoban_level_number', this.vm.sokobanLevel),
          highScoreValue: this.vm.modeHighScore, showPause: this.vm.realtime() || this.vm.hasComputerOpponent(), isPaused: this.vm.paused,
          showDifficulty: this.vm.sokobanLevel === 0 && hasDifficultyRules(this.vm.modeId),
          difficulty: this.vm.difficulty, onDifficultyChange: (d: GameDifficulty) => { this.vm.changeDifficulty(d); },
          onPauseToggle: () => { this.vm.togglePause(); }, onBack: () => { this.requestExit(); }, onRestart: () => { this.vm.startGame(); } })
  }

  @Builder
  OtherGameContent() {
    Scroll() {
      Column({ space: SpacingTokens.base }) {
        GameModePicker({ modes: modesForGame(this.gameId), selected: this.vm.modeId, best: this.vm.modeHighScore,
          hasProgress: this.vm.hasProgress(), onChange: (mode: string) => { this.vm.changeMode(mode); } })
        if (this.vm.hasComputerOpponent() && this.vm.state.outcome === 0) {
          ComputerOpponentPanel({ gameId: this.gameId, thinking: this.vm.computerThinking,
            player: this.vm.computerPlayer, difficulty: this.vm.difficulty })
        }
        this.Status()
        if (BRAIN_IDS.includes(this.vm.modeId)) { ExpansionBrainBoard({ gameId: this.vm.modeId, vm: this.vm, beatAreaLimit: this.contentHeight * 0.52 * 360 / 460 }) }
        if (this.gameId === 'fishing') { ExpansionLifeBoard({ vm: this.vm }) }
        if (CHESS_IDS.includes(this.gameId) || this.gameId === 'spider' || this.gameId === 'freecell') { ExpansionCardBoard({ gameId: this.gameId, vm: this.vm }) }
        if (ACTION_IDS.includes(this.gameId) || SPORTS_IDS.includes(this.gameId)) {
          ExpansionWorldBoard({ gameId: this.gameId, vm: this.vm,
            heightLimit: Math.max(this.screwBoardMinHeight, this.contentHeight - this.chaseControlsReserve) })
        }
        if (MATCHING_IDS.includes(this.gameId)) { ExpansionMatchingBoard({ gameId: this.gameId, vm: this.vm }) }
        if (SORTING_IDS.includes(this.gameId)) { ExpansionSortingBoard({ gameId: this.gameId, vm: this.vm }) }
        if (this.gameId === 'blockfit') {
          Stack() { this.GridBoard() }.width('100%').id('blockfit-board')
        } else if (['tilestack', 'arrowclear'].includes(this.gameId)) { this.GridBoard() }
        if (this.gameId === 'blockfit') { this.BlockTray() }
        if (this.gameId === 'tilestack') { this.TileTray() }
        if (this.gameId === 'watersort') { this.Tubes() }
        if (this.gameId === 'parkingjam') { ToyPuzzleBoard({ vm: this.vm, parking: true }) }
        if (this.gameId === 'screwout') {
          ToyPuzzleBoard({ vm: this.vm, boardHeightLimit: Math.max(this.screwBoardMinHeight, this.contentHeight - this.screwControlsReserve) })
        }
        if (this.gameId === 'blackhole') {
          ToyBlackholeStage({ vm: this.vm, heightLimit: Math.max(this.screwBoardMinHeight, this.contentHeight - this.chaseControlsReserve) })
        }
        if (this.vm.modeId === 'rhythm') {
          Stack() {
            this.Arena()
            if (this.vm.state.phase === 0) { Button($r('app.string.expansion_ready')).onClick(() => { this.vm.activate(); }) }
          }.width('100%').constraintSize({ maxWidth: this.contentHeight * 0.55 * 360 / 460 }).id('rhythm-four-board')
        } else if (this.vm.realtime() && this.gameId !== 'blackhole' && !ACTION_IDS.includes(this.gameId) && !SPORTS_IDS.includes(this.gameId) && !BRAIN_IDS.includes(this.vm.modeId) && this.gameId !== 'fishing') { this.Arena() }
        if (this.vm.modeId === 'runner' && this.vm.state.phase === 0) {
          Button($r('app.string.expansion_ready')).onClick(() => { this.vm.activate(); })
        }
        if (['solitaire', 'rhythm'].includes(this.vm.modeId)) {
          ExpansionExtras({ gameId: this.vm.modeId, vm: this.vm })
        }
        if (this.gameId === 'runner') {
          Row({ space: SpacingTokens.base }) {
            Button($r('app.string.expansion_left')).layoutWeight(1).height($r('app.float.expansion_control_height')).onClick(() => { this.vm.tap(0); })
            Button($r('app.string.expansion_right')).layoutWeight(1).height($r('app.float.expansion_control_height')).onClick(() => { this.vm.tap(1); })
          }.width('100%')
        }
        if (this.vm.puzzleStuck) {
          Text(this.gameId === 'watersort' ? $r('app.string.watersort_stuck') : $r('app.string.mahjongsolitaire_stuck'))
            .fontColor(SemanticColors.errorText).textAlign(TextAlign.Center).id('puzzle-stuck')
          Button($r('app.string.expansion_restart')).onClick(() => { this.vm.startGame(); })
        }
        if (!this.vm.realtime() && this.gameId !== 'freecell' && (!this.vm.puzzleStuck || this.vm.canUndo)) {
          Button($r('app.string.expansion_undo')).enabled(this.vm.canUndo).height($r('app.float.expansion_control_height'))
            .onClick(() => { this.vm.undo(); })
        }
      }.width('100%').constraintSize({ maxWidth: $r('app.float.expansion_board_max') })
        .padding({ left: SpacingTokens.base, right: SpacingTokens.base, bottom: SpacingTokens.xl })
    }.layoutWeight(1).width('100%').scrollBar(BarState.Off).enableScrollInteraction(!this.vm.dragging)
  }

  @Builder
  SokobanResult() {
    GameResultDialog({ shareGameId: this.gameId, title: this.vm.sokobanLevel === SOKOBAN_LEVELS.length ?
      $r('app.string.sokoban_all_cleared', SOKOBAN_LEVELS.length) : $r('app.string.sokoban_level_cleared', this.vm.sokobanLevel),
      detail: $r('app.string.result_detail_steps_complete_format', this.vm.state.moves), showDetail: true,
      primaryText: this.vm.sokobanLevel < SOKOBAN_LEVELS.length ? $r('app.string.sokoban_next_level') : $r('app.string.sokoban_retry_level'),
      onPrimary: () => {
        if (this.vm.sokobanLevel < SOKOBAN_LEVELS.length) { this.vm.selectSokobanLevel(this.vm.sokobanLevel + 1); }
        else { this.vm.startGame(); }
      },
      showSecondary: this.vm.sokobanLevel < SOKOBAN_LEVELS.length, secondaryText: $r('app.string.sokoban_retry_level'),
      onSecondary: () => { this.vm.startGame(); }, onExit: () => { this.pathStack.pop(); },
      cardStyle: true, celebrate: true })
  }

  @Builder
  PageContent() {
    Stack() {
      Column() {
        if (this.gameId === 'sokoban') {
          SokobanPlayArea({ vm: this.vm })
            .bindContentCover(this.vm.sokobanLevel > 0 && this.vm.state.outcome === 1, this.SokobanResult, {
              modalTransition: ModalTransition.NONE, backgroundColor: Color.Transparent,
              onWillDismiss: (action: DismissContentCoverAction) => { action.dismiss(); this.pathStack.pop(); }
            })
        } else {
          this.OtherGameContent()
        }
      }.width('100%').height('100%').padding({ bottom: this.safeArea.bottom })
      if (this.vm.modeId !== 'beatjump' && this.gameId !== 'fruitslice' && this.gameId !== 'drift') {
        Column() {
          ExpansionFeedback({ vm: this.vm })
        }.width('100%').height('100%').padding({ top: $r('app.float.art_feedback_top') }).hitTestBehavior(HitTestMode.None)
      }
      if (this.vm.paused) {
        Column({ space: SpacingTokens.base }) {
          Text($r('app.string.expansion_paused')).fontSize(FontTokens.sizeTitle).fontColor(SemanticColors.textPrimary)
          Text($r('app.string.game_settings_paused_hint')).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textSecondary)
        }.padding(SpacingTokens.xl).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.xl)
      }
      if (this.vm.sokobanLevel === 0 && this.vm.state.outcome !== 0 && !this.vm.chessAnimating) {
        GameResultDialog({ shareGameId: this.gameId, title: this.resultTitle(),
          detail: $r('app.string.collection_score_result', this.vm.state.score), showDetail: true,
          primaryText: $r('app.string.result_play_again'), onPrimary: () => { this.vm.startGame(); },
          showSecondary: true, secondaryText: this.gameId === 'buscolor' && this.vm.canUndo ? $r('app.string.expansion_undo') : $r('app.string.exit_confirm_leave'),
          onSecondary: () => { if (this.gameId === 'buscolor' && this.vm.canUndo) { this.vm.undo(); } else { this.pathStack.pop(); } },
          cardStyle: true, celebrate: this.vm.state.outcome === 1 && !this.vm.isDraw() })
      }
      if (this.vm.confirmExit) {
        ExitConfirmDialog({ onConfirm: () => { this.vm.dismissExitConfirm(); this.pathStack.pop(); }, onCancel: () => { this.vm.dismissExitConfirm(); } })
      }
    }.width('100%').height('100%').backgroundColor(SemanticColors.bg)
      .onAreaChange((oldArea: Area, area: Area) => { this.contentHeight = Number(area.height); })
  }

  build() {
    PageDestination({ gameId: this.gameId, header: () => { this.PageHeader(); }, content: () => { this.PageContent(); } })
  }
  @Builder
  Status() {
    Column({ space: SpacingTokens.sm }) {
      if (this.gameId === 'rhythm') {
        Row({ space: SpacingTokens.sm }) {
          Text($r('app.string.expansion_progress', this.vm.modeId === 'beatjump' ? this.vm.state.cursor : this.vm.state.moves, this.vm.state.goal)).fontColor(SemanticColors.textPrimary).id('rhythm-progress')
          Text($r('app.string.rhythm_errors', this.vm.state.errors)).fontColor(SemanticColors.warningText).id('rhythm-errors')
        }
      } else if (BRAIN_IDS.includes(this.gameId) || this.gameId === 'fishing') {
        if (this.gameId === 'fishing') {
          Text(this.vm.state.variant === 1 ? $r('app.string.fishing_summary', this.vm.state.cursor, this.vm.state.goal, this.vm.state.errors,
            this.vm.state.target.filter((count: number) => count > 0).length) :
            $r('app.string.fishing_summary_legacy', this.vm.state.cursor, this.vm.state.goal, this.vm.state.errors))
            .fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textPrimary).id('fishing-summary')
        } else {
          Text($r('app.string.expansion_progress', this.gameId === 'picturepuzzle' ? this.vm.state.board.filter((v: number, i: number) => v === i).length : this.vm.state.moves, this.vm.state.goal)).fontColor(SemanticColors.textPrimary)
        }
        if (this.gameId === 'melody') { Text($r('app.string.expansion_errors', this.vm.state.errors)).fontColor(SemanticColors.warningText) }
      } else if (CHESS_IDS.includes(this.gameId) || this.gameId === 'spider' || this.gameId === 'freecell') {
        Text($r('app.string.expansion_moves', this.vm.state.moves)).fontColor(SemanticColors.textSecondary)
      } else if (ACTION_IDS.includes(this.gameId) || SPORTS_IDS.includes(this.gameId)) {
        if (['shooter', 'tanks', 'survival'].includes(this.gameId)) {
          Text($r('app.string.expansion_health', this.vm.state.data[0])).fontColor(SemanticColors.textPrimary)
          Text($r('app.string.expansion_progress', this.vm.state.moves, this.vm.state.goal)).fontColor(SemanticColors.textSecondary)
        }
        if (['pingpong', 'airhockey'].includes(this.gameId)) { Text($r('app.string.expansion_match_score', this.vm.state.data[0], this.vm.state.data[1])).fontColor(SemanticColors.textPrimary) }
        if (['fruitslice', 'flappy'].includes(this.gameId)) { Text($r('app.string.expansion_progress', this.gameId === 'fruitslice' ? this.vm.state.moves : this.vm.state.cursor, this.vm.state.goal)).fontColor(SemanticColors.textPrimary) }
        if (['platformer', 'grapple', 'hillclimb'].includes(this.gameId)) { Text($r('app.string.expansion_progress', Math.floor(this.vm.state.pieces[0].x), this.vm.state.goal)).fontColor(SemanticColors.textPrimary) }
        if (this.gameId === 'platformer') {
          Progress({ value: this.vm.state.pieces[0].x, total: this.vm.state.goal, type: ProgressType.Linear })
            .width('70%').color(SemanticColors.primary).id('platformer-progress')
        }
        if (this.gameId === 'drift') { Text($r('app.string.expansion_time', Math.max(0, Math.ceil(this.vm.state.goal - this.vm.state.time)))).fontColor(SemanticColors.textPrimary) }
        if (this.gameId === 'fruitslice') {
          Text($r('app.string.expansion_fruitslice_errors', this.vm.state.errors)).id('fruitslice-misses')
            .fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Medium)
            .fontColor(this.vm.state.errors > 0 ? SemanticColors.errorText : SemanticColors.textPrimary)
            .backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.md)
            .padding({ left: SpacingTokens.md, right: SpacingTokens.md, top: SpacingTokens.xs, bottom: SpacingTokens.xs })
        }
      } else if (this.gameId === 'blockfit' || this.gameId === 'runner') {
        Text($r('app.string.expansion_target', this.vm.state.goal)).fontColor(SemanticColors.textPrimary)
        if (this.gameId === 'blockfit') { Text($r('app.string.expansion_controls_hint')).fontColor(SemanticColors.textSecondary) }
        else { Text($r('app.string.runner_lane', this.vm.state.cursor + 1)).fontColor(SemanticColors.textSecondary).id('runner-current-lane') }
      } else if (this.gameId === 'untangle') {
        Text($r('app.string.expansion_crossings', this.vm.state.data[0])).fontColor(SemanticColors.textPrimary)
      } else if (this.gameId === 'buscolor') {
        Text($r('app.string.expansion_progress', this.vm.state.cursor, this.vm.state.goal)).fontColor(SemanticColors.textPrimary)
      } else if (this.gameId === 'blackhole') {
        Row({ space: SpacingTokens.base }) {
          Text($r('app.string.expansion_progress', this.vm.state.moves, this.vm.state.goal)).fontColor(SemanticColors.textPrimary).id('blackhole-progress')
          Text($r('app.string.expansion_time', Math.max(0, Math.ceil(BlackholeLevels.limit(this.vm.state) - this.vm.state.time)))).fontColor(SemanticColors.textSecondary)
        }
      } else if (this.gameId === 'fisheat') {
        Text($r('app.string.expansion_progress', this.vm.state.moves, this.vm.state.goal)).fontColor(SemanticColors.textPrimary)
        if (this.gameId === 'fisheat' && this.vm.state.phase === 0) { Text($r('app.string.fisheat_steer')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary) }
      } else if (this.gameId === 'bubbleshooter') {
        Row({ space: SpacingTokens.md }) {
          Text($r('app.string.expansion_shots', Math.max(0, this.vm.state.goal - this.vm.state.moves))).fontColor(SemanticColors.textPrimary)
          Text($r('app.string.bubble_aim_instruction')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
        }
      } else if (this.gameId === 'fruitmerge') {
        Row({ space: SpacingTokens.sm }) {
          Text($r('app.string.expansion_drop', this.vm.state.next + 1)).fontColor(SemanticColors.textPrimary)
          Image(ExpansionArt.fruit(this.vm.state.next)).width(SpacingTokens.xl).height(SpacingTokens.xl).objectFit(ImageFit.Contain)
        }
        Row({ space: SpacingTokens.xs }) {
          Text($r('app.string.fruitmerge_chain')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
          ForEach(range(this.vm.state.goal + 1), (level: number) => {
            Image(ExpansionArt.fruit(level)).layoutWeight(1).height(SpacingTokens.lg).objectFit(ImageFit.Contain)
              .accessibilityText($r('app.string.expansion_drop', level + 1))
          }, (level: number) => level.toString())
        }.width('100%')
      } else if (this.gameId === 'groupclear') {
        Row({ space: SpacingTokens.sm }) {
          Text($r('app.string.groupclear_points', this.vm.state.score, this.vm.state.goal)).fontColor(SemanticColors.textPrimary).id('groupclear-points')
          Text($r('app.string.expansion_remaining', this.remaining(), this.vm.state.moves)).fontColor(SemanticColors.textSecondary).fontSize(FontTokens.sizeCaption).id('groupclear-remaining')
        }
        Progress({ value: this.vm.state.score, total: this.vm.state.goal, type: ProgressType.Linear }).width('80%').color(SemanticColors.primary)
      } else if (this.gameId === 'screwout') {
        Text($r('app.string.screwout_steps', this.remaining(), this.vm.state.moves)).fontColor(SemanticColors.textPrimary)
      } else {
        Text($r('app.string.expansion_remaining', this.remaining(), this.vm.state.moves)).fontColor(SemanticColors.textPrimary)
      }
      if (this.gameId === 'arrowclear') { Text($r('app.string.expansion_errors', this.vm.state.errors)).fontColor(SemanticColors.warningText) }
      if (this.gameId === 'screwout' && this.vm.state.phase === 0 && this.vm.state.tray.length === 3) {
        Text($r('app.string.expansion_full')).fontColor(SemanticColors.warningText)
      }
    }
  }
  @Builder
  GridBoard() {
    Column({ space: SpacingTokens.xs }) {
      ForEach(range(this.vm.state.rows), (row: number) => {
        Row({ space: SpacingTokens.xs }) {
          ForEach(range(this.vm.state.cols), (col: number) => {
            Column() {
              Stack({ alignContent: Alignment.BottomEnd }) {
                if (this.gameId === 'tilestack') {
                  this.TileStackCell(row * this.vm.state.cols + col)
                } else if (this.gameId === 'arrowclear') {
                  this.ClearArrowCell(row * this.vm.state.cols + col)
                } else {
                  GameArtTile({ image: this.cellArt(row * this.vm.state.cols + col),
                    description: $r('app.string.expansion_cell', row + 1, col + 1, this.cellText(row * this.vm.state.cols + col)),
                    onTap: () => { this.vm.tap(row * this.vm.state.cols + col); } })
                }
              }.width('100%').height('100%')
            }.layoutWeight(1).height('100%').padding(0).borderRadius(RadiusTokens.sm)
                .backgroundColor(this.gameId === 'arrowclear' ? SemanticColors.surface : this.color(this.value(row * this.vm.state.cols + col)))
              .opacity(['arrowclear', 'tilestack'].includes(this.gameId) && this.value(row * this.vm.state.cols + col) === 0 ? 0.25 : 1)
              .accessibilityText($r('app.string.expansion_cell', row + 1, col + 1, this.cellText(row * this.vm.state.cols + col)))
          }, (col: number) => col.toString())
        }.width('100%').layoutWeight(1)
      }, (row: number) => this.vm.state.cols + ':' + row)
    }.width('100%').aspectRatio(this.vm.state.cols / this.vm.state.rows).padding(SpacingTokens.sm)
      .backgroundColor(SemanticColors.boardBg).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base).clip(true)
  }
  @Builder
  ClearArrowCell(index: number) {
    Button(this.cellText(index), { type: ButtonType.Normal })
      .width('100%').height('100%').padding(0).fontSize(FontTokens.sizeDisplay).fontWeight(FontWeight.Bold)
      .fontColor(this.value(index) === 1 ? SemanticColors.primary : this.value(index) === 2 ? SemanticColors.successText :
        this.value(index) === 3 ? SemanticColors.warningText : SemanticColors.errorText)
      .borderRadius(RadiusTokens.sm).backgroundColor(SemanticColors.surface)
      .border({ width: 1, color: SemanticColors.border }).enabled(this.value(index) > 0).opacity(this.value(index) > 0 ? 1 : 0)
      .id('clear-arrow-' + index).accessibilityText($r('app.string.expansion_cell', Math.floor(index / this.vm.state.cols) + 1, index % this.vm.state.cols + 1, this.cellText(index)))
      .onClick(() => { Haptics.tap(); this.vm.tap(index); })
  }
  @Builder
  BlockTray() {
    Row({ space: SpacingTokens.sm }) {
      ForEach(range(3), (slot: number) => {
        Button({ type: ButtonType.Normal }) {
          Column({ space: SpacingTokens.xs }) {
            Text($r('app.string.expansion_piece', slot + 1)).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
            Column({ space: 2 }) {
              ForEach(range(3), (row: number) => {
                Row({ space: 2 }) {
                  ForEach(range(3), (col: number) => {
                    Stack() {
                      Image(ExpansionArt.block(slot)).width('100%').height('100%').objectFit(ImageFit.Fill)
                        .opacity(this.vm.state.tray[slot] >= 0 && col < BLOCK_SHAPES[this.vm.state.tray[slot]].cols && row < BLOCK_SHAPES[this.vm.state.tray[slot]].rows && BLOCK_SHAPES[this.vm.state.tray[slot]].cells.includes(row * BLOCK_SHAPES[this.vm.state.tray[slot]].cols + col) ? 1 : 0)
                      if (row === 0 && col === 0 && this.vm.state.tray[slot] >= 0) {
                        Stack() {}.width(SpacingTokens.sm).height(SpacingTokens.sm).borderRadius(RadiusTokens.full)
                          .backgroundColor(SemanticColors.surface).border({ width: 1, color: SemanticColors.textPrimary })
                      }
                    }.width(SpacingTokens.lg).height(SpacingTokens.lg)
                  }, (col: number) => col.toString())
                }
              }, (row: number) => row.toString())
            }
          }.padding(SpacingTokens.sm)
        }.layoutWeight(1).padding(0).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.sm)
          .border({ width: this.vm.state.selected === slot ? 2 : 0, color: SemanticColors.primary })
          .id('blockfit-slot-' + slot).enabled(this.vm.state.tray[slot] >= 0).onClick(() => { this.vm.choose(slot); })
      }, (slot: number) => slot.toString())
    }.width('100%')
  }
  @Builder
  TileStackCell(index: number) {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.depth(index) > 1) {
        Stack() {}.width('92%').height('92%').borderRadius(RadiusTokens.sm)
          .backgroundColor(SemanticColors.border).border({ width: 1, color: SemanticColors.textSecondary })
      }
      GameArtTile({ image: this.cellArt(index), available: this.depth(index) > 0,
        description: $r('app.string.expansion_cell', Math.floor(index / this.vm.state.cols) + 1, index % this.vm.state.cols + 1, this.cellText(index)),
        onTap: () => { this.vm.tap(index); } })
        .width('92%').height('92%').margin({ bottom: (this.depth(index) - 1) * 2, right: (this.depth(index) - 1) * 2 })
      if (this.depth(index) > 0) {
        Text($r('app.string.tilestack_depth', this.depth(index))).fontSize(FontTokens.sizeCaption)
          .fontColor(SemanticColors.textPrimary).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.xs)
          .padding({ left: 2, right: 2 }).hitTestBehavior(HitTestMode.None)
      }
    }.width('100%').height('100%').id('tilestack-cell-' + index)
  }
  @Builder
  TileTray() {
    Column({ space: SpacingTokens.sm }) {
      Text($r('app.string.expansion_tray', this.vm.state.tray.length)).fontColor(SemanticColors.textPrimary)
      Row({ space: SpacingTokens.xs }) {
        ForEach(range(7), (index: number) => {
          Image(this.vm.state.tray[index] === undefined ? $r('app.media.exp_empty') : ExpansionArt.tile(this.vm.state.tray[index] - 1))
            .layoutWeight(1).height(42).objectFit(ImageFit.Contain).accessibilityText(this.symbol(this.vm.state.tray[index] ?? 0))
            .border({ width: this.vm.state.tray[index] !== undefined && this.vm.state.tray.filter((tile: number) => tile === this.vm.state.tray[index]).length === 2 ? 2 : 0, color: SemanticColors.primary })
            .borderRadius(RadiusTokens.sm)
        }, (index: number) => index.toString())
      }.width('100%')
    }
  }
  @Builder
  Tubes() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
      ForEach(range(this.vm.state.cols), (tube: number) => {
        Button({ type: ButtonType.Normal }) {
          Stack() {
            Column({ space: 0 }) {
              ForEach([3, 2, 1, 0], (layer: number) => {
                Stack() {
                  Image(ExpansionArt.water(this.vm.state.board[tube * 4 + layer] - 1))
                    .objectFit(ImageFit.Fill).width('100%').height('100%').accessibilityLevel('no')
                  if (this.vm.state.board[tube * 4 + layer] > 0) {
                    Text(this.symbol(this.vm.state.board[tube * 4 + layer]))
                      .fontSize(FontTokens.sizeBody).fontColor($r('app.color.play_color_piece_text'))
                      .padding({ left: SpacingTokens.xs, right: SpacingTokens.xs })
                      .backgroundColor($r('app.color.color_cue_background')).borderRadius(RadiusTokens.xs)
                  }
                }.width('100%').layoutWeight(1).opacity(this.vm.state.board[tube * 4 + layer] > 0 ? 1 : 0)
              }, (layer: number) => layer.toString())
            }.width('52%').height('78%').translate({ y: 8 }).borderRadius(RadiusTokens.base).clip(true)
            Image($r('app.media.exp_tube')).width('100%').height('100%').objectFit(ImageFit.Fill).hitTestBehavior(HitTestMode.None)
          }.width('100%').height('100%').renderGroup(true)
        }.width(this.vm.state.cols === 7 ? '22%' : '29%').height($r('app.float.expansion_tube_height')).margin(SpacingTokens.xs).padding(0)
          .id('watersort-tube-' + tube).translate({ y: this.vm.state.selected === tube ? -SpacingTokens.xs : 0 })
          .backgroundColor(this.vm.state.selected === tube ? SemanticColors.primaryLight : Color.Transparent).borderRadius(RadiusTokens.base)
          .border({ width: this.vm.state.selected === tube ? 2 : 0, color: SemanticColors.primary })
          .accessibilityText($r('app.string.expansion_tube', tube + 1, this.vm.state.board.slice(tube * 4, tube * 4 + 4).join(', ')))
          .onClick(() => { this.vm.tap(tube); })
      }, (tube: number) => tube.toString())
    }.width('100%').backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' })
      .borderRadius(RadiusTokens.base).clip(true)
  }
  @Builder
  Arena() {
    Stack({ alignContent: Alignment.TopStart }) {
      ExpansionBackdrop(this.gameId)
      if (this.gameId === 'runner') {
        Row() {
          ForEach(range(3), (lane: number) => {
            Column() {}.layoutWeight(1).height('100%')
              .backgroundColor(lane === this.vm.state.cursor ? $r('app.color.runner_current_lane') : Color.Transparent)
              .id('runner-lane-' + lane)
              .border({ width: { left: lane === 0 ? 0 : 2 }, color: SemanticColors.textSecondary })
          }, (lane: number) => lane.toString())
        }.width('100%').height('100%').id('runner-lanes')
          .priorityGesture(PanGesture({ direction: PanDirection.Horizontal, distance: SpacingTokens.base })
            .onActionEnd((event: GestureEvent) => {
              if (this.vm.state.phase === 1 && Math.abs(event.offsetX) >= SpacingTokens.base) { this.vm.tap(event.offsetX < 0 ? 0 : 1); }
            }))
      } else if (this.gameId === 'rhythm') {
        Row() {
          ForEach(range(4), (lane: number) => {
            Text('').layoutWeight(1).height('100%').border({ width: { right: 2 }, color: SemanticColors.textSecondary })
          }, (lane: number) => lane.toString())
        }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
        Text('').width('100%').height(4).backgroundColor(SemanticColors.primary).translate({ y: 398 * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
      }
      if (this.gameId === 'fisheat') {
        Stack() {}.width('100%').height('100%').id('fisheat-field').hitTestBehavior(HitTestMode.None)
      }
      if (this.gameId === 'bubbleshooter') {
        ForEach(range(120), (index: number) => {
          Image(ExpansionArt.bubble(this.vm.state.board[index] - 1)).width(38 * this.arenaScale()).height(38 * this.arenaScale()).objectFit(ImageFit.Contain)
            .translate({ x: (this.vm.bubbleX(index) - 19) * this.arenaScale(), y: (this.vm.bubbleY(index) - 19) * this.arenaScale() })
            .opacity(this.vm.state.board[index] > 0 ? 1 : 0).hitTestBehavior(HitTestMode.None)
        }, (index: number) => index.toString())
        Stack() {}.width('100%').height('100%').id('bubble-target-area').hitTestBehavior(HitTestMode.None)
        Stack() {
          Stack() {}.width('100%').height('100%').backgroundColor(SemanticColors.surfaceHover)
            .borderRadius(RadiusTokens.full).border({ width: 2, color: SemanticColors.textSecondary })
          if (this.vm.state.pieces.length === 0) {
            Image(ExpansionArt.bubble(this.vm.state.next - 1)).width('86%').height('86%').objectFit(ImageFit.Contain)
              .accessibilityText($r('app.string.expansion_next_ball'))
          }
        }.width(46 * this.arenaScale()).height(46 * this.arenaScale())
          .translate({ x: 157 * this.arenaScale(), y: 412 * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
      } else if (this.gameId === 'fruitmerge') {
        Stack() {}.width('100%').height('100%').id('fruitmerge-field').hitTestBehavior(HitTestMode.None)
        Text($r('app.string.expansion_warning')).width('100%').fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.warningText)
          .translate({ y: (FRUIT_WARNING_Y - 24) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
        Text('').width('100%').height(1).backgroundColor(SemanticColors.warning)
          .translate({ y: FRUIT_WARNING_Y * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
      }
      ForEach(this.vm.worldPieces, (rendered: ExpansionRenderPiece) => {
        if (this.gameId === 'fisheat' && rendered.piece.kind === 10) {
          Stack() {}.width((rendered.piece.r * 2 + 8) * this.arenaScale()).height((rendered.piece.r * 2 + 8) * this.arenaScale())
            .border({ width: 2, color: $r('app.color.toy_screw_gold') }).borderRadius(RadiusTokens.full)
            .translate({ x: (rendered.piece.x - rendered.piece.r - 4) * this.arenaScale(), y: (rendered.piece.y - rendered.piece.r - 4) * this.arenaScale() })
            .id('fisheat-player').hitTestBehavior(HitTestMode.None)
        } else if (this.gameId === 'fisheat' && isDangerousFish(this.vm.state.pieces[0].r, rendered.piece.r)) {
          Stack() {}.width((rendered.piece.r * 2 + 6) * this.arenaScale()).height((rendered.piece.r * 2 + 6) * this.arenaScale())
            .border({ width: 2, color: SemanticColors.errorText, style: BorderStyle.Dashed }).borderRadius(RadiusTokens.full)
            .translate({ x: (rendered.piece.x - rendered.piece.r - 3) * this.arenaScale(), y: (rendered.piece.y - rendered.piece.r - 3) * this.arenaScale() })
            .id('fisheat-danger-' + rendered.id).hitTestBehavior(HitTestMode.None)
        }
        if (this.gameId === 'runner') {
          Image(ExpansionArt.piece(this.gameId, rendered.piece)).objectFit(ImageFit.Contain)
            .width(rendered.piece.r * 2 * this.arenaScale()).height(rendered.piece.r * 2 * this.arenaScale())
            .translate({ x: (rendered.piece.x - rendered.piece.r) * this.arenaScale(), y: (rendered.piece.y - rendered.piece.r) * this.arenaScale() })
            .id(rendered.piece.kind === 6 ? 'runner-character' : (rendered.piece.color === 1 ? 'runner-coin-' : 'runner-obstacle-') + rendered.id)
            .hitTestBehavior(HitTestMode.None)
        } else {
          Image(ExpansionArt.piece(this.gameId, rendered.piece)).objectFit(ImageFit.Contain)
            .width(this.arenaRadius(rendered.piece) * 2 * this.arenaScale()).height(this.arenaRadius(rendered.piece) * 2 * this.arenaScale())
            .scale({ x: (this.gameId === 'fisheat' && rendered.piece.vx < 0 ? -1 : 1) * rendered.piece.r / this.arenaRadius(rendered.piece), y: rendered.piece.r / this.arenaRadius(rendered.piece) })
            .translate({ x: (rendered.piece.x - this.arenaRadius(rendered.piece)) * this.arenaScale(), y: (rendered.piece.y - this.arenaRadius(rendered.piece)) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
        }
      }, (rendered: ExpansionRenderPiece) => rendered.id.toString())
    }.width('100%').aspectRatio(360 / 460).backgroundColor(SemanticColors.boardBg).borderRadius(RadiusTokens.base).clip(true)
      .onAreaChange((previous: Area, current: Area) => { this.measureArena(current); })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && ['blackhole', 'fisheat'].includes(this.gameId)) { this.vm.setDragging(true); }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.vm.setDragging(false); }
        if ((event.type === TouchType.Down || (event.type === TouchType.Move && ['blackhole', 'fisheat'].includes(this.gameId))) && event.touches.length > 0 && this.arenaScale() > 0) {
          this.vm.aim(event.touches[0].x / this.arenaScale(), event.touches[0].y / this.arenaScale());
        }
      })
  }
}
