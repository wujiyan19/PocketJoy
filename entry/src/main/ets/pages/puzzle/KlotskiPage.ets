import { PageDestination } from '../../components/PageDestination';
import { resolveString } from '../../common/I18nUtils';
import { GameSessionTransfer } from '../../common/GameSessionTransfer';
/**
 * 华容道 —— View 层（纯展示与组装）
 *
 * 只持有 @Local viewModel，读取其 @Trace 状态、转发操作；不 import Model 类型。
 * 规则见 model/game/KlotskiModel.ets，状态编排见 viewmodel/KlotskiViewModel.ets。
 */
import { SemanticColors, RadiusTokens, FontTokens, SpacingTokens } from '../../common/DesignTokens';
import { Haptics } from '../../common/Haptics';
import { HarmonyMotion } from '../../common/HarmonyMotion';
import { GameHeader } from '../../components/GameHeader';
import { GameDifficulty, GameStatus } from '../../common/GameConstants';
import { SafeAreaInsets, SafeAreaState } from '../../common/SafeAreaInsets';
import { GameResultDialog } from '../../components/GameResultDialog';
import { ExitConfirmDialog } from '../../components/ExitConfirmDialog';
import { GameLifecycleBus } from '../../common/GameLifecycleBus';
import { ScreenUtils } from '../../common/ScreenUtils';
import { KlotskiPieceView, KlotskiViewModel } from '../../viewmodel/KlotskiViewModel';

const BW = 4;
const BH = 5;

@ComponentV2
export struct KlotskiPage {
  @Param pathStack: NavPathStack = new NavPathStack();
  @Local safeArea: SafeAreaState = SafeAreaInsets.state;
  @Local viewModel: KlotskiViewModel = new KlotskiViewModel();
  @Local cell: number = 65;
  // 无障碍字符串缓存
  @Local a11yBlockFormat: string = '';

  @Monitor('viewModel.status', 'viewModel.confirmExit')
  playTimeStateChanged(): void { GameLifecycleBus.updatePlayTime(this.viewModel); }

  aboutToAppear(): void {
    this.cell = ScreenUtils.calcCell(BW, 560, 28, 48);
    const context = this.getUIContext().getHostContext();
    if (context) {
      this.a11yBlockFormat = resolveString($r('app.string.a11y_klotski_block_format'), context);
    }
    GameLifecycleBus.attach(this.viewModel);
    if (!GameSessionTransfer.restore(this.viewModel)) { this.viewModel.startGame(); }
    this.playTimeStateChanged();
  }

  aboutToDisappear(): void {
    GameLifecycleBus.detach(this.viewModel);
    this.viewModel.dispose();
  }

  /** 返回请求统一入口：进行中弹确认，其余直接返回 */
  requestExit(): void {
    if (this.viewModel.requestBack()) {
      return;
    }
    this.pathStack.pop();
  }

  private step(): number { return this.cell + 4; }

  getPieceImage(kind: number): Resource {
    if (kind === 1) { return $r('app.media.play_klotski_target'); }
    if (kind === 2) { return $r('app.media.play_klotski_horizontal'); }
    if (kind === 3) { return $r('app.media.play_klotski_vertical'); }
    return $r('app.media.play_klotski_soldier');
  }

  @Styles
  pressedFeedback() {
    .opacity(0.72)
    .scale({ x: 0.96, y: 0.96 })
  }

  @Builder
  MoveKey(symbol: Resource, label: Resource, id: string, dx: number, dy: number) {
    Button() { SymbolGlyph(symbol).fontSize(FontTokens.sizeSubtitle).fontColor([SemanticColors.textPrimary]) }
      .width(56).height(48).type(ButtonType.Normal).borderRadius(RadiusTokens.base)
      .backgroundColor(SemanticColors.surface).border({ width: 1.5, color: $r('app.color.klotski_exit_frame') })
      .id(id).accessibilityText(label).clickEffect(HarmonyMotion.press(this.getUIContext()))
      .onClick(() => { Haptics.tap(); this.viewModel.moveBlock(dx, dy); })
  }

  @Builder
  PageHeader() {
    GameHeader({ gameId: 'klotski', pathStack: this.pathStack, hasProgress: (): boolean => this.viewModel.hasProgress(),
          gameTitle: $r('app.string.game_klotski_name'),
          showScore: false,
          showPause: false,
          subtitle: $r('app.string.klotski_drag_hint'),
          difficulty: this.viewModel.difficulty,
          onDifficultyChange: (d: GameDifficulty) => { this.viewModel.changeDifficulty(d); },
          onBack: () => { this.requestExit(); },
          onPauseToggle: () => {},
          onRestart: () => { this.viewModel.startGame(); }
        })
  }

  @Builder
  PageContent() {
    Stack() {
      Column().width('100%').height('100%')
        .linearGradient({ angle: 180, colors: [[SemanticColors.gradientScreen[0], 0], [SemanticColors.gradientScreen[1], 0.5], [SemanticColors.gradientScreen[2], 1]] })

      Column() {
        Text($r('app.string.game_klotski_subtitle_format', this.viewModel.stepCount))
          .id('klotski-steps').fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Medium)
          .fontColor(SemanticColors.textPrimary).padding(SpacingTokens.xs)
        Column() {
          Stack({ alignContent: Alignment.TopStart }) {
            Image($r('app.media.play_klotski_board'))
              .width(this.step() * BW + 8).height(this.step() * BH + 8)
              .objectFit(ImageFit.Fill)

            ForEach(this.viewModel.piecesForView(), (piece: KlotskiPieceView) => {
              Stack() {
                Image(this.getPieceImage(piece.kind))
                  .width(piece.w * this.step() - 4)
                  .height(piece.h * this.step() - 4)
                  .objectFit(ImageFit.Fill)
                Text(piece.label)
                  .fontSize(Math.max(18, this.cell * 0.3))
                  .fontWeight(FontWeight.Bold)
                  .fontColor(piece.kind === 1 || piece.kind === 3 ?
                    $r('app.color.play_color_piece_text') : $r('app.color.play_piece_text'))
              }
              .width(piece.w * this.step() - 4).height(piece.h * this.step() - 4)
              .border({ width: piece.selected ? 3 : 0, color: SemanticColors.primary })
              .borderRadius(RadiusTokens.base)
              .translate({ x: 6 + piece.x * this.step(), y: 6 + piece.y * this.step() })
              .accessibilityText(this.a11yBlockFormat.replace('%1$s', piece.label))
              .id('klotski-piece-' + piece.id)
              .gesture(PanGesture({ fingers: 1, direction: PanDirection.All, distance: SpacingTokens.md })
                .onActionEnd((event: GestureEvent) => {
                  if (!piece.selected) { this.viewModel.selectBlockAt(piece.y, piece.x); }
                  if (Math.abs(event.offsetX) > Math.abs(event.offsetY)) {
                    this.viewModel.moveBlock(event.offsetX > 0 ? 1 : -1, 0);
                  } else { this.viewModel.moveBlock(0, event.offsetY > 0 ? 1 : -1); }
                }))
              .stateStyles({ pressed: this.pressedFeedback })
              .onClick(() => this.viewModel.selectBlockAt(piece.y, piece.x))
            }, (piece: KlotskiPieceView) => piece.id)
          }
          .width(this.step() * BW + 8).height(this.step() * BH + 8).id('klotski-board')
          Row() {
            Column().layoutWeight(1).height(SpacingTokens.sm).backgroundColor($r('app.color.klotski_exit_frame'))
            Text($r('app.string.klotski_exit')).layoutWeight(2).textAlign(TextAlign.Center).fontSize(FontTokens.sizeCaption)
              .fontWeight(FontWeight.Medium).fontColor(SemanticColors.textPrimary)
            Column().layoutWeight(1).height(SpacingTokens.sm).backgroundColor($r('app.color.klotski_exit_frame'))
          }.width(this.step() * BW + 8).height(SpacingTokens.lg).margin({ bottom: SpacingTokens.md })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          .onAreaChange((oldValue: Area, newValue: Area) => {
            const width: number = parseFloat(newValue.width as string);
            const height: number = parseFloat(newValue.height as string);
            if (Number.isFinite(width) && Number.isFinite(height) && width > 0 && height > 0) {
              this.cell = ScreenUtils.calcCellForArea(width, height, BW, BH, 560, 28, BH * 4 + 8 + SpacingTokens.lg + SpacingTokens.md);
            }
          })

        Column({ space: SpacingTokens.sm }) {
          this.MoveKey($r('sys.symbol.arrow_up'), $r('app.string.a11y_direction_up'), 'control-pad-up', 0, -1)
          Row({ space: SpacingTokens.md }) {
            this.MoveKey($r('sys.symbol.arrow_left'), $r('app.string.a11y_direction_left'), 'control-pad-left', -1, 0)
            Column().width(56).height(48).accessibilityLevel('no')
            this.MoveKey($r('sys.symbol.arrow_right'), $r('app.string.a11y_direction_right'), 'control-pad-right', 1, 0)
          }
          this.MoveKey($r('sys.symbol.arrow_down'), $r('app.string.a11y_direction_down'), 'control-pad-down', 0, 1)
        }.width('100%')
      }.width('100%').height('100%').padding({ bottom: this.safeArea.bottom })

      if (this.viewModel.status === GameStatus.OVER) {
        GameResultDialog({ shareGameId: 'klotski',
          symbol: $r('sys.symbol.checkmark_circle'),
          celebrate: true,
          symbolColor: SemanticColors.success,
          title: $r('app.string.result_klotski_success'),
          detail: $r('app.string.result_detail_steps_complete_format', this.viewModel.stepCount),
          detailColor: SemanticColors.warning,
          showDetail: true,
          primaryText: $r('app.string.result_play_again'),
          onPrimary: () => { this.viewModel.startGame(); }, showSecondary: true,
          secondaryText: $r('app.string.action_back'), onSecondary: () => { this.pathStack.pop(); }
        })
      }

      if (this.viewModel.confirmExit) {
        ExitConfirmDialog({
          onConfirm: () => {
            this.viewModel.dismissExitConfirm();
            this.pathStack.pop();
          },
          onCancel: () => { this.viewModel.dismissExitConfirm(); }
        })
      }
    }.width('100%').height('100%')
  }

  build() {
    PageDestination({ gameId: 'klotski', header: () => { this.PageHeader(); }, content: () => { this.PageContent(); } })
  }
}
