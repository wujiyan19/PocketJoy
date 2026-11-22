import { PageDestination } from '../../components/PageDestination';
import { GameInfo, GameDifficulty } from '../../common/GameConstants';
import { SemanticColors, FontTokens, RadiusTokens, SpacingTokens } from '../../common/DesignTokens';
import { SafeAreaInsets, SafeAreaState } from '../../common/SafeAreaInsets';
import { GameLifecycleBus } from '../../common/GameLifecycleBus';
import { GameSessionTransfer } from '../../common/GameSessionTransfer';
import { GameDataManager } from '../../model/GameData';
import { CollectionViewModel } from '../../viewmodel/CollectionViewModel';
import { GameHeader } from '../../components/GameHeader';
import { ControlPad } from '../../components/ControlPad';
import { ExitConfirmDialog } from '../../components/ExitConfirmDialog';
import { GameResultDialog } from '../../components/GameResultDialog';
import { CollectionArt } from '../../common/CollectionArt';
import { modesForGame } from '../../common/GameModes';
import { GameModePicker } from '../../components/GameModePicker';
import { SettingsChoice } from '../../components/SettingsChoice';
import { CollectionMathBoard } from './CollectionMathBoard';

@ComponentV2
export struct CollectionPage {
  @Local safeArea: SafeAreaState = SafeAreaInsets.state;
  @Param gameId: string = '';
  @Param pathStack: NavPathStack = new NavPathStack();
  @Local vm: CollectionViewModel = new CollectionViewModel();
  @Local game: GameInfo | undefined = undefined;
  private artLabels: string[] = [];

  @Monitor('vm.isFinished', 'vm.confirmExit')
  playTimeStateChanged(): void { GameLifecycleBus.updatePlayTime(this.vm); }

  aboutToAppear(): void {
    this.game = GameDataManager.getGameById(this.gameId); this.vm.init(this.gameId);
    const labels: Resource[] = [$r('app.string.collection_empty'), $r('app.string.collection_art_robot'),
      $r('app.string.collection_art_exit'), $r('app.string.collection_art_wall'), $r('app.string.collection_art_path'),
      $r('app.string.collection_art_player'), $r('app.string.collection_art_on'), $r('app.string.collection_art_off'),
      $r('app.string.collection_art_filled'), $r('app.string.collection_art_peg'), $r('app.string.collection_art_legal'),
      $r('app.string.nonogram_mark')];
    const context = this.getUIContext().getHostContext();
    if (context) {
      this.artLabels = labels.map((label: Resource) => {
        try { return context.resourceManager.getStringSync(label.id); } catch (e) { return ''; }
      });
    }
    GameLifecycleBus.attach(this.vm);
    if (!GameSessionTransfer.restore(this.vm)) { this.vm.startGame(); }
    this.playTimeStateChanged();
  }
  aboutToDisappear(): void { GameLifecycleBus.detach(this.vm); this.vm.dispose(); }
  requestExit(): void { if (!this.vm.requestBack()) { this.pathStack.pop(); } }
  rows(): number[] {
    return new Array<number>(Math.ceil(this.vm.state.board.length / this.vm.state.cols)).fill(0).map((v: number, i: number) => i);
  }
  columns(): number[] { return new Array<number>(this.vm.state.cols).fill(0).map((v: number, i: number) => i); }
  showBoard(): boolean {
    return !this.vm.isQuiz() && !['hanoi', 'nim', 'reaction'].includes(this.gameId);
  }
  cellText(index: number): string {
    const value: number = this.vm.state.board[index];
    if (this.gameId === 'schulte' || this.gameId === 'memorysequence') { return value.toString(); }
    if (this.gameId === 'flood') { return (value + 1).toString(); }
    if (this.gameId === 'nonogram' && value === 2) { return '×'; }
    if (this.gameId === 'peg' && this.vm.legal(index)) { return '◎'; }
    return this.vm.legal(index) ? '·' : '';
  }
  cellDescription(index: number): string {
    const value: number = this.vm.state.board[index];
    let label: number = 0;
    if (this.gameId === 'maze') {
      label = index === this.vm.state.cursor ? 1 : index === this.vm.state.answer ? 2 : value === 1 ? 3 : 4;
    } else if (this.vm.isDuel() && value > 0) {
      return (this.artLabels[5] ?? '').replace('%d', value.toString());
    } else if (this.gameId === 'lights') {
      label = value === 1 ? 6 : 7;
    } else if (this.gameId === 'nonogram') {
      label = value === 1 ? 8 : value === 2 ? 11 : 0;
    } else if (this.gameId === 'peg' && value === 1) {
      label = 9;
    } else if (this.vm.legal(index)) { label = 10;
    } else if (this.cellText(index).length > 0) { return this.cellText(index); }
    return this.artLabels[label] ?? '';
  }
  indices(count: number): number[] {
    return new Array<number>(count).fill(0).map((v: number, i: number) => i);
  }
  discs(post: number): number[] {
    const result: number[] = [];
    for (let i = 0; i < this.vm.state.board.length; i++) {
      if (this.vm.state.board[i] === post) { result.push(i); }
    }
    return result;
  }
  memoryCards(): number[] {
    if (this.gameId === 'memorysequence' && this.vm.state.phase !== 0) {
      return new Array<number>(this.vm.state.target.length).fill(0);
    }
    return this.vm.state.phase === 0 ? this.vm.state.target : this.vm.state.board;
  }
  choiceText(index: number): string {
    const value: number = this.vm.state.choices[index];
    if (this.vm.modeId === 'compare') { return value === -1 ? '＜' : value === 0 ? '＝' : '＞'; }
    return (this.gameId === 'flood' ? value + 1 : value).toString();
  }
  reactionText(): Resource {
    if (this.vm.state.phase === 0) { return $r('app.string.collection_reaction_start'); }
    return this.vm.state.phase === 1 ? $r('app.string.collection_reaction_wait') : $r('app.string.collection_reaction_go');
  }
  resultTitle(): Resource {
    if (this.gameId === 'reaction' && this.vm.state.outcome === 2) { return $r('app.string.reaction_early'); }
    if (this.vm.isDuel()) {
      return this.vm.state.outcome === 3 ? $r('app.string.collection_draw') : $r('app.string.collection_player_win', this.vm.state.outcome);
    }
    return this.vm.state.outcome === 1 ? $r('app.string.collection_win') : $r('app.string.collection_fail');
  }
  resultDetail(): Resource {
    if (this.gameId === 'reaction') { return this.vm.state.outcome === 1 ? $r('app.string.collection_reaction_result', this.vm.state.answer) : $r('app.string.reaction_retry_hint'); }
    if (this.vm.isDuel()) { return $r('app.string.collection_steps', this.vm.state.moves); }
    return $r('app.string.collection_score_result', this.vm.state.score);
  }

  @Builder
  PageHeader() {
    GameHeader({ gameId: this.gameId, pathStack: this.pathStack, hasProgress: (): boolean => this.vm.hasProgress(), gameTitle: this.game?.name ?? '', showScore: false, showPause: false,
          rulesModeId: this.gameId === 'arithmetic' ? this.vm.modeId : '',
          showDifficulty: !['tictactoe', 'gomoku', 'reversi', 'fourline', 'reaction'].includes(this.gameId),
          difficulty: this.vm.difficulty, onDifficultyChange: (d: GameDifficulty) => { this.vm.changeDifficulty(d); },
          onBack: () => { this.requestExit(); }, onRestart: () => { this.vm.startGame(); } })
  }

  @Builder
  PageContent() {
    Stack() {
      Column() {

        Scroll() {
          Column({ space: SpacingTokens.base }) {
            if (this.gameId === 'arithmetic') {
              CollectionMathBoard({ vm: this.vm })
            } else {
            GameModePicker({ modes: modesForGame(this.gameId), selected: this.vm.modeId, best: this.vm.modeHighScore,
              hasProgress: this.vm.hasProgress(), onChange: (mode: string) => { this.vm.changeMode(mode); } })
            this.StatusLine()
            if (this.vm.isQuiz() && this.vm.feedback.length > 0) {
              Text(this.vm.lastCorrect ? $r('app.string.collection_correct', this.vm.feedback) : $r('app.string.collection_wrong', this.vm.feedback))
                .fontSize(FontTokens.sizeBodySmall).fontColor(this.vm.lastCorrect ? SemanticColors.successText : SemanticColors.warningText)
            }
            if (this.gameId === 'nonogram') {
              Row({ space: SpacingTokens.sm }) {
                SettingsChoice({ label: $r('app.string.nonogram_fill'), selected: !this.vm.state.markEmpty,
                  onChoose: () => { this.vm.setMarkEmpty(false); } }).id('nonogram-fill')
                SettingsChoice({ label: $r('app.string.nonogram_mark'), selected: this.vm.state.markEmpty,
                  onChoose: () => { this.vm.setMarkEmpty(true); } }).id('nonogram-mark')
              }.width('100%')
            }
            if (this.gameId === 'memorysequence') { this.SequenceRecall() }
            else if (this.gameId === 'missing') { this.MemoryCards() }
            if (this.vm.isQuiz() && this.gameId !== 'missing') { this.Question() }
            if (this.gameId === 'flood') { this.FloodBoard() }
            else if (this.gameId === 'nonogram') { this.NonogramBoard() }
            else if (this.gameId === 'maze') {
              Stack() { this.Board() }.width('100%').id('maze-board')
                .priorityGesture(PanGesture({ fingers: 1, direction: PanDirection.All, distance: SpacingTokens.md })
                  .onActionEnd((e: GestureEvent) => {
                    this.vm.move(Math.abs(e.offsetX) > Math.abs(e.offsetY) ? (e.offsetX > 0 ? 1 : 3) : (e.offsetY > 0 ? 2 : 0));
                  }))
            }
            else if (this.showBoard() && this.gameId !== 'memorysequence') { this.Board() }
            if (this.gameId === 'nim') { this.Stones() }
            if (this.gameId === 'hanoi') { this.Towers() }
            if (this.gameId === 'reaction') {
              Button({ type: ButtonType.Normal }) {
                Column({ space: SpacingTokens.sm }) {
                  Image(CollectionArt.signal(this.vm.state.phase)).width($r('app.float.collection_art_beacon')).aspectRatio(1)
                  Text(this.reactionText()).fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary)
                    .id('reaction-state')
                }.padding(SpacingTokens.base)
              }
                .width('100%').aspectRatio(0.95).id('reaction-pad')
                .borderRadius(RadiusTokens.xl)
                .backgroundColor(this.vm.state.phase === 2 ? $r('app.color.reaction_go_bg') :
                  this.vm.state.phase === 1 ? $r('app.color.reaction_wait_bg') : SemanticColors.selectionSurface)
                .accessibilityText(this.reactionText())
                .onClick(() => { this.vm.tap(0); })
            }
            if (this.gameId === 'flood') {
              Row({ space: SpacingTokens.sm }) {
                ForEach(this.vm.state.choices, (color: number) => {
                  Button({ type: ButtonType.Normal }) {
                    Stack() {
                      Image(CollectionArt.flood(color)).width('100%').height('100%')
                        .objectFit(ImageFit.Fill).hitTestBehavior(HitTestMode.None)
                      Row({ space: SpacingTokens.xs }) {
                        if (this.vm.state.board[0] === color) {
                          SymbolGlyph($r('sys.symbol.checkmark')).fontSize(FontTokens.sizeBody).fontColor([$r('app.color.collection_ink')])
                        }
                        Text((color + 1).toString()).fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold).fontColor($r('app.color.collection_ink'))
                      }
                    }.width('100%').height('100%')
                  }.layoutWeight(1).height($r('app.float.collection_control_height')).padding(0).borderRadius(RadiusTokens.sm)
                    .backgroundColor(Color.Transparent).clip(true)
                    .enabled(this.vm.state.board[0] !== color).id('flood-color-' + color)
                    .accessibilityText($r('app.string.flood_choose_color', color + 1)).onClick(() => { this.vm.choose(color); })
                }, (color: number) => color.toString())
              }.width('100%')
            } else if (this.vm.state.choices.length > 0 && this.gameId !== 'hanoi' && !(this.gameId === 'missing' && this.vm.state.phase === 0)) {
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
                ForEach(this.vm.state.choices, (value: number, index: number) => {
                  Button({ type: ButtonType.Normal }) {
                    Stack() {
                      Image(this.gameId === 'flood' ? CollectionArt.flood(value) : $r('app.media.col_ceramic_cell'))
                        .width('100%').height('100%').objectFit(ImageFit.Fill)
                      Text(this.choiceText(index)).fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold)
                        .fontColor(this.gameId === 'flood' ? $r('app.color.collection_ink') : $r('app.color.collection_art_ink'))
                    }.width('100%').height('100%')
                  }
                    .width('44%').height($r('app.float.collection_control_height')).margin(SpacingTokens.xs)
                    .padding(0).borderRadius(RadiusTokens.sm).backgroundColor(Color.Transparent)
                    .accessibilityText(this.choiceText(index)).onClick(() => { this.vm.choose(index); })
                }, (value: number, index: number) => this.vm.state.round + ':' + index + ':' + value)
              }.width('100%')
            }
            if (this.gameId === 'missing' && this.vm.state.phase === 0) {
              Button($r('app.string.collection_ready')).onClick(() => { this.vm.action(); })
            }
            if (this.gameId === 'nonogram') {
              Button($r('app.string.collection_check')).onClick(() => { this.vm.action(); })
              if (this.vm.checked && this.vm.state.outcome === 0) {
                Text($r('app.string.collection_check_again')).fontColor(SemanticColors.warningText)
              }
            }
            }
          }.width('100%').constraintSize({ maxWidth: $r('app.float.collection_board_max') })
            .padding({ left: SpacingTokens.base, right: SpacingTokens.base, bottom: SpacingTokens.xl })
        }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
        if (this.gameId === 'maze') {
          ControlPad({
            buttonSize: 64,
            onUp: () => { this.vm.move(0); },
            onRight: () => { this.vm.move(1); },
            onDown: () => { this.vm.move(2); },
            onLeft: () => { this.vm.move(3); }
          }).width('100%').padding({ top: SpacingTokens.sm, bottom: SpacingTokens.base }).backgroundColor(SemanticColors.selectionSurface)
        }
      }.width('100%').height('100%').padding({ bottom: this.safeArea.bottom })
      if (this.vm.state.outcome !== 0) {
        GameResultDialog({ shareGameId: this.gameId, title: this.resultTitle(), detail: this.resultDetail(), showDetail: true,
          primaryText: $r('app.string.result_play_again'), onPrimary: () => { this.vm.startGame(); },
          showSecondary: true, secondaryText: $r('app.string.exit_confirm_leave'), onSecondary: () => { this.pathStack.pop(); }, cardStyle: true,
          celebrate: this.vm.state.outcome === 1 || (this.vm.isDuel() && this.vm.state.outcome === 2) })
      }
      if (this.vm.confirmExit) {
        ExitConfirmDialog({ onConfirm: () => { this.vm.dismissExitConfirm(); this.pathStack.pop(); },
          onCancel: () => { this.vm.dismissExitConfirm(); } })
      }
    }.width('100%').height('100%').backgroundColor(SemanticColors.bg)
  }

  build() {
    PageDestination({ gameId: this.gameId, header: () => { this.PageHeader(); }, content: () => { this.PageContent(); } })
  }
  @Builder
  StatusLine() {
    Column({ space: SpacingTokens.sm }) {
      if (this.gameId === 'schulte') {
        Text(GameDataManager.getModeTime(this.vm.modeId, this.vm.difficulty) > 0 ?
          $r('app.string.record_elapsed', (this.vm.state.elapsedMs / 1000).toFixed(1),
            (GameDataManager.getModeTime(this.vm.modeId, this.vm.difficulty) / 1000).toFixed(1)) :
          $r('app.string.collection_elapsed_no_best', (this.vm.state.elapsedMs / 1000).toFixed(1)))
          .fontColor(SemanticColors.textSecondary).id('schulte-time')
      }
      if (this.gameId === 'hanoi') {
        Text(GameDataManager.getModeTime(this.vm.modeId, this.vm.difficulty) > 0 ?
          $r('app.string.record_elapsed', (this.vm.state.elapsedMs / 1000).toFixed(1),
            (GameDataManager.getModeTime(this.vm.modeId, this.vm.difficulty) / 1000).toFixed(1)) :
          $r('app.string.collection_elapsed_no_best', (this.vm.state.elapsedMs / 1000).toFixed(1)))
          .fontColor(SemanticColors.textSecondary).id('hanoi-time')
        Text(this.vm.state.minimumMoves > 0 ? $r('app.string.hanoi_goal', this.vm.state.goalPost + 1, this.vm.state.minimumMoves) :
          $r('app.string.hanoi_goal_only', this.vm.state.goalPost + 1)).fontColor(SemanticColors.textPrimary)
      }
      if (this.vm.isDuel()) {
        Row({ space: SpacingTokens.sm }) {
          Image(CollectionArt.piece(this.gameId, this.vm.state.player)).width($r('app.float.collection_art_turn')).aspectRatio(1)
          Text($r('app.string.collection_turn', this.vm.state.player)).fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeBodyLarge)
        }
      }
      else if (this.gameId === 'lights') {
        Text($r('app.string.lights_status', this.vm.state.moves, this.vm.state.board.filter((lamp: number) => lamp === 1).length))
          .fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary).id('lights-status')
        Text($r('app.string.lights_goal')).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textSecondary)
      }
      else if (this.gameId === 'maze') {
        Text($r('app.string.collection_steps', this.vm.state.moves)).fontSize(FontTokens.sizeSubtitle)
          .fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary).id('maze-steps')
        Text($r('app.string.maze_move_hint')).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textSecondary)
      }
      else if (this.gameId === 'peg') {
        Text($r('app.string.peg_status', this.vm.state.board.filter((piece: number) => piece === 1).length, this.vm.state.moves))
          .fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary).id('peg-status')
        Text($r('app.string.peg_hint')).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textSecondary)
      }
      else if (this.gameId === 'reaction') {
        Text(this.vm.reactionBestMs >= 0 ? $r('app.string.reaction_best', this.vm.reactionBestMs) : $r('app.string.reaction_no_best'))
          .fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary).id('reaction-best')
        Text($r('app.string.reaction_tap_hint')).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textSecondary)
      }
      else if (this.vm.isQuiz()) { Text($r('app.string.collection_round', Math.min(10, this.vm.state.round + 1), this.vm.state.score)).fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeBodyLarge) }
      else if (this.gameId === 'flood') {
        Text($r('app.string.collection_limit', this.vm.state.moves, this.vm.state.answer)).fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeBodyLarge).id('flood-steps')
        Text($r('app.string.flood_region', this.vm.floodCells.length, this.vm.state.board.length))
          .fontColor(SemanticColors.textSecondary).fontSize(FontTokens.sizeBody).id('flood-region')
      }
      else if (this.gameId === 'schulte') {
        Text($r('app.string.collection_target', this.vm.state.answer)).fontColor(SemanticColors.primary)
          .fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold).padding({ left: SpacingTokens.base, right: SpacingTokens.base })
          .backgroundColor(SemanticColors.selectionSurface).borderRadius(RadiusTokens.full).id('schulte-target')
        if (this.vm.feedback.length > 0) {
          Text($r('app.string.schulte_wrong', this.vm.feedback, this.vm.state.answer)).fontColor(SemanticColors.warningText)
            .fontSize(FontTokens.sizeBodySmall).id('schulte-warning')
        } else if (this.vm.state.moves === 0) {
          Text($r('app.string.schulte_start')).fontColor(SemanticColors.textSecondary).fontSize(FontTokens.sizeBodySmall)
        }
      }
      else if (this.gameId === 'memorysequence') {
        Text(this.vm.state.phase === 0 ? $r('app.string.sequence_memorize') :
          $r('app.string.collection_progress', this.vm.state.cursor, this.vm.state.target.length))
          .fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold).id('memory-status')
      }
      else if (this.gameId !== 'reaction') { Text($r('app.string.collection_steps', this.vm.state.moves)).fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeBodyLarge)
        .id(this.gameId === 'hanoi' ? 'hanoi-steps' : '') }
      if (this.gameId === 'nim') { Text($r('app.string.collection_stones', this.vm.state.board[0])).fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeTitle) }
    }
  }
  @Builder
  NonogramBoard() {
    Column() {
      Row() {
        Blank().width('20%')
        ForEach(this.columns(), (col: number) => {
          Text(this.vm.clue(col, true).split(' ').join('\n')).layoutWeight(1).textAlign(TextAlign.Center)
            .fontSize(FontTokens.sizeBody).fontWeight(FontWeight.Bold)
            .fontColor(this.vm.clueSatisfied(col, true) ? SemanticColors.successText : SemanticColors.textPrimary)
            .id('nonogram-col-' + col)
        }, (col: number) => col.toString())
      }.width('100%').layoutWeight(1)
      ForEach(this.rows(), (row: number) => {
        Row() {
          Text(this.vm.clue(row, false)).width('20%').textAlign(TextAlign.Center)
            .fontSize(FontTokens.sizeBody).fontWeight(FontWeight.Bold)
            .fontColor(this.vm.clueSatisfied(row, false) ? SemanticColors.successText : SemanticColors.textPrimary)
            .id('nonogram-row-' + row)
          ForEach(this.columns(), (col: number) => {
            Button({ type: ButtonType.Normal }) { this.Cell(row * this.vm.state.cols + col) }
              .layoutWeight(1).height('100%').padding(0).backgroundColor(Color.Transparent).borderRadius(RadiusTokens.xs)
              .id('nonogram-cell-' + row + '-' + col)
              .accessibilityText($r('app.string.collection_cell', row + 1, col + 1, this.cellDescription(row * this.vm.state.cols + col)))
              .onClick(() => { this.vm.tap(row * this.vm.state.cols + col); })
          }, (col: number) => col.toString())
        }.width('100%').layoutWeight(1)
      }, (row: number) => row.toString())
    }.width('100%').aspectRatio(1).id('nonogram-board')
  }
  @Builder
  FloodBoard() {
    Column({ space: SpacingTokens.xs }) {
      ForEach(this.rows(), (row: number) => {
        Row({ space: SpacingTokens.xs }) {
          ForEach(this.columns(), (col: number) => {
            Stack({ alignContent: Alignment.TopStart }) {
              this.Cell(row * this.vm.state.cols + col)
              if (row === 0 && col === 0) {
                Text('◆').fontSize(9).fontColor(SemanticColors.primary).textAlign(TextAlign.Center)
                  .width(14).height(14).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.full)
                  .margin({ left: SpacingTokens.xs, top: SpacingTokens.xs }).id('flood-origin-marker').accessibilityLevel('no')
              }
            }.layoutWeight(1).height('100%')
              .border({ width: this.vm.floodCells.includes(row * this.vm.state.cols + col) ? 2 : 0, color: SemanticColors.primary })
              .borderRadius(RadiusTokens.xs).id('flood-cell-' + row + '-' + col)
              .accessibilityText($r('app.string.collection_cell', row + 1, col + 1, this.cellText(row * this.vm.state.cols + col)))
          }, (col: number) => col.toString())
        }.width('100%').layoutWeight(1)
      }, (row: number) => row.toString())
    }.width('100%').aspectRatio(1).id('flood-board')
  }
  @Builder
  Board() {
    Stack() {
      Image(CollectionArt.board(this.gameId)).width('100%').height('100%').objectFit(ImageFit.Fill)
      Column({ space: this.gameId === 'gomoku' || this.gameId === 'maze' ? 0 : SpacingTokens.xs }) {
        ForEach(this.rows(), (row: number) => {
          Row({ space: this.gameId === 'gomoku' || this.gameId === 'maze' ? 0 : SpacingTokens.xs }) {
            ForEach(this.columns(), (col: number) => {
              Button({ type: ButtonType.Normal }) { this.Cell(row * this.vm.state.cols + col) }
                .layoutWeight(1).height('100%').padding(0).borderRadius(RadiusTokens.xs)
                .backgroundColor(Color.Transparent)
                .border({ width: this.vm.state.selected === row * this.vm.state.cols + col ? 2 : 0, color: SemanticColors.primary })
                .opacity(this.gameId === 'peg' && this.vm.state.board[row * this.vm.state.cols + col] === -1 ? 0 :
                  this.gameId === 'schulte' && this.vm.state.board[row * this.vm.state.cols + col] < this.vm.state.answer ? 0.4 : 1)
                .enabled(!(this.gameId === 'memorysequence' && this.vm.state.phase === 0) &&
                  !(this.gameId === 'peg' && this.vm.state.board[row * this.vm.state.cols + col] === -1))
                .accessibilityText($r('app.string.collection_cell', row + 1, col + 1, this.cellDescription(row * this.vm.state.cols + col)))
                .id(this.gameId === 'schulte' ? 'schulte-number-' + this.vm.state.board[row * this.vm.state.cols + col] :
                  ['lights', 'maze', 'peg'].includes(this.gameId) ? this.gameId + '-cell-' + row + '-' + col : '')
                .onClick(() => { this.vm.tap(row * this.vm.state.cols + col); })
            }, (col: number) => this.vm.state.cols.toString() + ':' + col.toString())
          }.width('100%').layoutWeight(1)
        }, (row: number) => this.vm.state.cols.toString() + ':' + row.toString())
      }.width('100%').height('100%').padding(SpacingTokens.md)
    }.width('100%').aspectRatio(this.vm.state.cols / Math.max(1, this.rows().length))
      .id(this.gameId === 'lights' ? 'lights-board' : '')
  }
  @Builder
  Cell(index: number) {
    Stack() {
      Image(CollectionArt.cell(this.gameId, this.vm.state.board[index])).width('100%').height('100%').objectFit(ImageFit.Fill)
      if (this.vm.isDuel() && this.vm.state.board[index] > 0) {
        Image(CollectionArt.piece(this.gameId, this.vm.state.board[index])).width('94%').height('94%').objectFit(ImageFit.Contain)
      } else if (this.gameId === 'peg' && this.vm.state.board[index] === 1) {
        Image($r('app.media.col_peg')).width('94%').height('94%').objectFit(ImageFit.Contain)
      } else if (this.gameId === 'maze' && index === this.vm.state.cursor) {
        Image($r('app.media.col_robot')).width('100%').height('100%').objectFit(ImageFit.Contain)
          .backgroundColor(SemanticColors.selectionSurface).borderRadius(RadiusTokens.sm).id('maze-robot')
      } else if (this.gameId === 'maze' && index === this.vm.state.answer) {
        Image($r('app.media.col_portal')).width('100%').height('100%').objectFit(ImageFit.Contain)
          .border({ width: 2, color: SemanticColors.successText }).borderRadius(RadiusTokens.sm).id('maze-exit')
      }
      if (this.gameId === 'peg' && this.vm.legal(index)) {
        Text('◎').fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold)
          .fontColor(SemanticColors.primary).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.full)
      } else if (this.cellText(index).length > 0) {
        Text(this.cellText(index)).fontSize(this.vm.state.cols >= 7 ? FontTokens.sizeBody : FontTokens.sizeSubtitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.gameId === 'flood' ? $r('app.color.collection_ink') :
            this.gameId === 'reversi' ? Color.White : $r('app.color.collection_art_ink'))
      }
    }.width('100%').height('100%')
  }
  @Builder
  Question() {
    Stack() {
      Image(CollectionArt.question(this.gameId)).width('100%').height('100%').objectFit(ImageFit.Fill)
      Column({ space: SpacingTokens.sm }) {
        Image(this.game?.icon).width($r('app.float.collection_art_question_icon')).aspectRatio(1)
        Text(this.vm.state.prompt).fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.collection_art_ink')).textAlign(TextAlign.Center).width('100%')
      }.padding(SpacingTokens.xl).width('100%')
    }.width('100%').height($r('app.float.collection_art_question_height'))
  }
  @Builder
  SequenceRecall() {
    Column({ space: SpacingTokens.md }) {
      Column({ space: SpacingTokens.xs }) {
        ForEach(this.indices(this.vm.state.target.length > 6 ? 2 : 1), (row: number) => {
          Row({ space: SpacingTokens.xs }) {
            ForEach(this.indices(this.vm.state.target.length > 6 ? 4 : this.vm.state.target.length), (col: number) => {
              if (this.vm.state.phase === 0) {
                Text(this.vm.state.target[row * 4 + col].toString()).layoutWeight(1).height($r('app.float.collection_control_height'))
                  .textAlign(TextAlign.Center).fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold)
                  .backgroundColor(SemanticColors.selectionSurface).fontColor(SemanticColors.primary)
                  .borderRadius(RadiusTokens.sm).id('memory-item-' + (row * 4 + col))
              } else {
                Text(row * 4 + col < this.vm.state.cursor ? '✓' : '•').layoutWeight(1).height($r('app.float.collection_control_height'))
                  .textAlign(TextAlign.Center).fontSize(FontTokens.sizeSubtitle).fontColor(SemanticColors.textSecondary)
                  .backgroundColor(SemanticColors.surfaceHover).borderRadius(RadiusTokens.sm)
                  .accessibilityText($r('app.string.collection_art_hidden')).id('memory-item-' + (row * 4 + col))
              }
            }, (col: number) => col.toString())
          }.width('100%')
        }, (row: number) => row.toString())
      }.width('100%').id('memory-sequence')
      if (this.vm.state.phase === 0) {
        Button($r('app.string.collection_ready')).width('100%').height($r('app.float.expansion_control_height'))
          .backgroundColor(SemanticColors.primary).fontColor(SemanticColors.textOnPrimary).id('memory-ready')
          .onClick(() => { this.vm.action(); })
      }
      Column({ space: SpacingTokens.sm }) {
        ForEach(this.indices(3), (row: number) => {
          Row({ space: SpacingTokens.sm }) {
            ForEach(this.indices(3), (col: number) => {
              Button((row * 3 + col + 1).toString()).type(ButtonType.Normal).layoutWeight(1)
                .height($r('app.float.expansion_control_height')).fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold)
                .backgroundColor(SemanticColors.surface).fontColor(SemanticColors.textPrimary).borderRadius(RadiusTokens.md)
                .border({ width: 1, color: SemanticColors.border }).enabled(this.vm.state.phase === 1)
                .id('memory-key-' + (row * 3 + col + 1)).onClick(() => { this.vm.tap(row * 3 + col); })
            }, (col: number) => col.toString())
          }.width('100%')
        }, (row: number) => row.toString())
      }.width('100%')
    }.width('100%')
  }
  @Builder
  MemoryCards() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
      ForEach(this.memoryCards(), (value: number, index: number) => {
        Stack() {
          Image(this.gameId === 'memorysequence' && this.vm.state.phase !== 0 ?
            $r('app.media.col_card_back') : $r('app.media.col_card_front')).width('100%').height('100%').objectFit(ImageFit.Fill)
          if (!(this.gameId === 'memorysequence' && this.vm.state.phase !== 0)) {
            Text(value.toString()).fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold).fontColor($r('app.color.collection_art_ink'))
          }
        }.width($r('app.float.collection_art_card_width')).height($r('app.float.collection_art_card_height'))
          .margin(SpacingTokens.xs)
          .accessibilityText(this.gameId === 'memorysequence' && this.vm.state.phase !== 0 ?
            $r('app.string.collection_art_hidden') : $r('app.string.collection_art_card', value))
      }, (value: number, index: number) => index.toString() + ':' + value.toString())
    }.width('100%').padding(SpacingTokens.sm).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.base)
  }
  @Builder
  Stones() {
    Stack() {
      Image($r('app.media.col_table_tray')).width('100%').height('100%').objectFit(ImageFit.Fill)
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignContent: FlexAlign.Center }) {
        ForEach(this.indices(this.vm.state.board[0]), (index: number) => {
          Image($r('app.media.col_stone')).width('14%').height($r('app.float.collection_art_stone')).objectFit(ImageFit.Contain)
        }, (index: number) => index.toString())
      }.width('100%').height('100%').padding(SpacingTokens.base)
    }.width('100%').height($r('app.float.collection_art_tray_height'))
      .accessibilityText($r('app.string.collection_stones', this.vm.state.board[0]))
  }
  @Builder
  Towers() {
    Row({ space: SpacingTokens.sm }) {
      ForEach([0, 1, 2], (post: number) => {
        Button({ type: ButtonType.Normal }) {
          Column({ space: SpacingTokens.sm }) {
            Text(post === this.vm.state.goalPost ? $r('app.string.hanoi_goal_only', post + 1) : $r('app.string.collection_post', post + 1))
              .fontSize(FontTokens.sizeBody).fontWeight(post === this.vm.state.goalPost ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(post === this.vm.state.goalPost ? SemanticColors.primary : SemanticColors.textPrimary)
            Stack({ alignContent: Alignment.Bottom }) {
              Image($r('app.media.col_hanoi_post')).width('100%').height('100%').objectFit(ImageFit.Fill)
              Column() {
                ForEach(this.discs(post), (disc: number) => {
                  Stack() {
                    Image(CollectionArt.disc(disc)).width('100%').height('100%').objectFit(ImageFit.Fill)
                    Text((disc + 1).toString()).fontSize(FontTokens.sizeBody).fontWeight(FontWeight.Bold).fontColor($r('app.color.collection_ink'))
                  }.width((44 + disc * 13) + '%').height($r('app.float.collection_art_disc_height'))
                }, (disc: number) => disc.toString())
              }.width('100%').padding({ bottom: SpacingTokens.xl })
            }.width('100%').layoutWeight(1)
          }.width('100%').height('100%').padding(SpacingTokens.xs)
        }.layoutWeight(1).height($r('app.float.collection_art_tower_height')).padding(SpacingTokens.xs)
          .backgroundColor(this.vm.state.selected === post ? SemanticColors.primaryLight : SemanticColors.surface)
          .borderRadius(RadiusTokens.base)
          .border({ width: this.vm.state.selected === post ? 3 : post === this.vm.state.goalPost ? 1 : 0, color: SemanticColors.primary })
          .id('hanoi-post-' + post)
          .accessibilityText($r('app.string.collection_art_tower', post + 1, this.discs(post).map((disc: number) => disc + 1).join(', ')))
          .onClick(() => { this.vm.choose(post); })
      })
    }.width('100%')
  }
}
