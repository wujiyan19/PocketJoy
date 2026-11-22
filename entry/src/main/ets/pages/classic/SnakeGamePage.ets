import { PageDestination } from '../../components/PageDestination';
import { GameSessionTransfer } from '../../common/GameSessionTransfer';
/**
 * 贪吃蛇 —— View 层（纯展示与组装）
 *
 * 只持有 @Local viewModel，读取其 @Trace 状态、转发用户操作；
 * 不包含任何游戏规则/计时/持久化，也不 import Model 类型。
 * 规则见 model/game/SnakeModel.ets，状态编排见 viewmodel/SnakeViewModel.ets。
 */
import { SemanticColors, RadiusTokens, FontTokens, SpacingTokens } from '../../common/DesignTokens';
import { GameHeader } from '../../components/GameHeader';
import { Haptics } from '../../common/Haptics';
import { GameResultDialog } from '../../components/GameResultDialog';
import { GameDifficulty, GameStatus } from '../../common/GameConstants';
import { SafeAreaInsets, SafeAreaState } from '../../common/SafeAreaInsets';
import { ScreenUtils } from '../../common/ScreenUtils';
import { range } from '../../common/Range';
import { GameLifecycleBus } from '../../common/GameLifecycleBus';
import { ExitConfirmDialog } from '../../components/ExitConfirmDialog';
import { SnakeCellData, SnakeCellKind, SnakeViewModel } from '../../viewmodel/SnakeViewModel';

const COLS = 20;
const ROWS = 20;
const BOARD_RIM = 2;

@ComponentV2
export struct SnakeGamePage {
  @Param pathStack: NavPathStack = new NavPathStack();
  @Local safeArea: SafeAreaState = SafeAreaInsets.state;
  @Local viewModel: SnakeViewModel = new SnakeViewModel();
  @Local cell: number = 16;
  private idx20: number[] = range(COLS);

  @Monitor('viewModel.status', 'viewModel.confirmExit', 'viewModel.started')
  playTimeStateChanged(): void { GameLifecycleBus.updatePlayTime(this.viewModel); }

  aboutToAppear(): void {
    this.cell = ScreenUtils.calcCell(COLS, 560, 24, 8);
    // 挂到生命周期总线：切后台暂停/恢复、系统侧滑返回拦截都经总线转发
    // （页面 onPageHide/onPageShow 仅对 @Entry 生效，本页是 @ComponentV2，不可依赖）
    GameLifecycleBus.attach(this.viewModel);
    if (!GameSessionTransfer.restore(this.viewModel)) { this.viewModel.startGame(); }
    this.playTimeStateChanged();
  }

  aboutToDisappear(): void {
    GameLifecycleBus.detach(this.viewModel);
    this.viewModel.dispose();
  }

  /** 返回请求统一入口：进行中弹确认（被 requestBack 拦截），其余直接返回 */
  requestExit(): void {
    if (this.viewModel.requestBack()) {
      return;
    }
    this.pathStack.pop();
  }

  getSnakeImage(kind: SnakeCellKind): Resource {
    if (kind === SnakeCellKind.HEAD) { return $r('app.media.play_snake_head'); }
    if (kind === SnakeCellKind.TAIL) { return $r('app.media.play_snake_tail'); }
    if (kind === SnakeCellKind.CORNER) { return $r('app.media.play_snake_corner'); }
    if (kind === SnakeCellKind.FOOD) { return $r('app.media.play_snake_food'); }
    return $r('app.media.play_snake_body');
  }

  @Builder
  DirectionKey(symbol: Resource, label: Resource, id: string, turn: () => void) {
    Button() {
      SymbolGlyph(symbol).fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Medium)
        .fontColor([$r('app.color.snake_key_ink')])
    }.type(ButtonType.Normal).width($r('app.float.snake_key_width')).height($r('app.float.snake_key_height'))
      .borderRadius(RadiusTokens.md).backgroundColor($r('app.color.snake_key_face'))
      .border({ width: 1, color: $r('app.color.snake_frame') }).accessibilityText(label).id(id)
      .onClick(() => { Haptics.tap(); turn(); })
  }

  @Builder
  PageHeader() {
    GameHeader({ gameId: 'snake', pathStack: this.pathStack, hasProgress: (): boolean => this.viewModel.hasProgress(), gameTitle: $r('app.string.game_snake_name'), // 得分/最高分已由下方大字指标卡展示，关闭标题栏的小字重复显示
          showScore: false,
          isPaused: this.viewModel.status === GameStatus.PAUSED,
          difficulty: this.viewModel.difficulty,
          onDifficultyChange: (d: GameDifficulty) => { this.viewModel.changeDifficulty(d); },
          onBack: () => { this.requestExit(); },
          onPauseToggle: () => { this.viewModel.togglePause(); },
          onRestart: () => { this.viewModel.startGame(); } })
  }

  @Builder
  PageContent() {
    Stack() {
      Column().width('100%').height('100%')
        .linearGradient({ angle: 180, colors: [[SemanticColors.gradientScreen[0], 0], [SemanticColors.gradientScreen[1], 0.5], [SemanticColors.gradientScreen[2], 1]] })

      Column() {


        Row() {
          Column() {
            Text($r('app.string.score_label')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textTertiary)
            Text('' + this.viewModel.score).fontSize(FontTokens.sizeHeadline).fontWeight(FontTokens.weightBold).fontColor(SemanticColors.accent)
          }.layoutWeight(1).padding(8).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.lg)
          .alignItems(HorizontalAlign.Center).margin({ left: 16 })

          Column() {
            Text($r('app.string.high_score_label')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textTertiary)
            Text('' + this.viewModel.highScore).fontSize(FontTokens.sizeHeadline).fontWeight(FontTokens.weightBold).fontColor(SemanticColors.textPrimary)
          }.layoutWeight(1).padding(8).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.lg)
          .alignItems(HorizontalAlign.Center).margin({ left: 8, right: 16 })
        }.margin({ top: 12, bottom: 12 })

        Column() {
          Column() {
            Stack({ alignContent: Alignment.TopStart }) {
              Column() {
                ForEach(this.idx20, (row: number) => {
                  Row() {
                    ForEach(this.idx20, (col: number) => {
                      Column().width(this.cell).height(this.cell)
                        .backgroundColor((row + col) % 2 === 0 ? $r('app.color.snake_floor') : $r('app.color.snake_floor_alt'))
                    }, (col: number) => col.toString())
                  }
                }, (row: number) => row.toString())
              }.renderGroup(true).accessibilityLevel('no')
              ForEach(this.viewModel.visibleCells, (tile: SnakeCellData) => {
                Image(this.getSnakeImage(tile.kind)).width(this.cell).height(this.cell).objectFit(ImageFit.Contain)
                  .rotate({ z: 1, angle: tile.rotation, centerX: '50%', centerY: '50%' })
                  .position({ x: tile.id % COLS * this.cell, y: Math.floor(tile.id / COLS) * this.cell })
              }, (tile: SnakeCellData) => tile.id.toString())
            }.width(this.cell * COLS).height(this.cell * ROWS)
          }.width(this.cell * COLS + BOARD_RIM * 2).height(this.cell * ROWS + BOARD_RIM * 2)
          .padding(BOARD_RIM).borderRadius(RadiusTokens.sm).clip(true).backgroundColor($r('app.color.snake_frame'))
          .id('snake-board').gesture(PanGesture({ fingers: 1, direction: PanDirection.All, distance: SpacingTokens.md })
            .onActionStart((event: GestureEvent) => {
              if (Math.abs(event.offsetX) > Math.abs(event.offsetY)) {
                if (event.offsetX > 0) { this.viewModel.turnRight(); } else { this.viewModel.turnLeft(); }
              } else {
                if (event.offsetY > 0) { this.viewModel.turnDown(); } else { this.viewModel.turnUp(); }
              }
            }))
          .accessibilityGroup(true)
          .accessibilityText($r('app.string.a11y_snake_board', (this.viewModel.snake[0]?.y ?? -1) + 1,
            (this.viewModel.snake[0]?.x ?? -1) + 1, this.viewModel.food.y + 1, this.viewModel.food.x + 1, this.viewModel.snake.length))
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          .onAreaChange((oldValue: Area, newValue: Area) => {
            const width: number = parseFloat(newValue.width as string);
            const height: number = parseFloat(newValue.height as string);
            if (Number.isFinite(width) && Number.isFinite(height) && width > 0 && height > 0) {
              this.cell = ScreenUtils.calcCellForArea(width, height, COLS, ROWS, 560, 24, BOARD_RIM * 2);
            }
          })

        Row() {
          if (!this.viewModel.started) {
            Text($r('app.string.snake_start_hint')).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textSecondary)
          }
        }.height(SpacingTokens.xxl).justifyContent(FlexAlign.Center).width('100%')
        Column({ space: SpacingTokens.xs }) {
          this.DirectionKey($r('sys.symbol.arrow_up'), $r('app.string.a11y_direction_up'), 'control-pad-up', () => { this.viewModel.turnUp(); })
          Row({ space: SpacingTokens.xs }) {
            this.DirectionKey($r('sys.symbol.arrow_left'), $r('app.string.a11y_direction_left'), 'control-pad-left', () => { this.viewModel.turnLeft(); })
            Column().width($r('app.float.snake_key_width')).height($r('app.float.snake_key_height')).accessibilityLevel('no')
            this.DirectionKey($r('sys.symbol.arrow_right'), $r('app.string.a11y_direction_right'), 'control-pad-right', () => { this.viewModel.turnRight(); })
          }
          this.DirectionKey($r('sys.symbol.arrow_down'), $r('app.string.a11y_direction_down'), 'control-pad-down', () => { this.viewModel.turnDown(); })
        }.width('100%').padding({ bottom: SpacingTokens.sm })
      }.width('100%').height('100%').padding({ bottom: this.safeArea.bottom })

      if (this.viewModel.status === GameStatus.OVER) {
        GameResultDialog({ shareGameId: 'snake',
          symbol: $r('sys.symbol.star_fill'),
          symbolColor: SemanticColors.warning,
          title: $r('app.string.result_game_over'),
          detail: $r('app.string.result_detail_score_format', this.viewModel.score),
          detailColor: SemanticColors.accent,
          showDetail: true,
          primaryText: $r('app.string.result_play_again'),
          onPrimary: () => { this.viewModel.startGame(); },
          secondaryText: $r('app.string.action_back'),
          showSecondary: true,
          onSecondary: () => { this.pathStack.pop(); }
        })
      }

      if (this.viewModel.confirmExit) {
        ExitConfirmDialog({
          onConfirm: () => {
            this.pathStack.pop();
          },
          onCancel: () => { this.viewModel.dismissExitConfirm(); }
        })
      }
    }.width('100%').height('100%')
  }

  build() {
    PageDestination({ gameId: 'snake', header: () => { this.PageHeader(); }, content: () => { this.PageContent(); } })
  }
}
