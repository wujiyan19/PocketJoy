import { PageDestination } from '../../components/PageDestination';
import { resolveString } from '../../common/I18nUtils';
import { GameSessionTransfer } from '../../common/GameSessionTransfer';
/**
 * 记忆翻牌 —— View 层（纯展示与组装）
 *
 * 只持有 @Local viewModel，读取其 @Trace 状态、转发操作；不 import Model 类型。
 * 规则见 model/game/MemoryCardModel.ets，状态编排见 viewmodel/MemoryCardViewModel.ets。
 */
import { SemanticColors, RadiusTokens, FontTokens, ShadowTokens, SpacingTokens } from '../../common/DesignTokens';
import { GameHeader } from '../../components/GameHeader';
import { GameDifficulty, GameStatus } from '../../common/GameConstants';
import { SafeAreaInsets, SafeAreaState } from '../../common/SafeAreaInsets';
import { GameResultDialog } from '../../components/GameResultDialog';
import { ExitConfirmDialog } from '../../components/ExitConfirmDialog';
import { GameLifecycleBus } from '../../common/GameLifecycleBus';
import { Haptics } from '../../common/Haptics';
import { ScreenUtils } from '../../common/ScreenUtils';
import { range } from '../../common/Range';
import { MemoryCardViewModel } from '../../viewmodel/MemoryCardViewModel';

// 棋盘列数固定为 4；行数随难度变化
const COLS = 4;

@ComponentV2
export struct MemoryCardPage {
  @Param pathStack: NavPathStack = new NavPathStack();
  @Local safeArea: SafeAreaState = SafeAreaInsets.state;
  @Local viewModel: MemoryCardViewModel = new MemoryCardViewModel();
  @Local cardW: number = 78;
  @Local rowIdx: number[] = range(4);
  private colIdx: number[] = range(COLS);
  private boardWidthVp: number = 0;
  private boardHeightVp: number = 0;
  // 无障碍字符串缓存
  @Local a11yCardFlippedFormat: string = '';
  @Local a11yCardHiddenFormat: string = '';

  @Monitor('viewModel.status', 'viewModel.confirmExit')
  playTimeStateChanged(): void { GameLifecycleBus.updatePlayTime(this.viewModel); }

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context) {
      this.a11yCardFlippedFormat = resolveString($r('app.string.a11y_card_flipped_format'), context);
      this.a11yCardHiddenFormat = resolveString($r('app.string.a11y_card_hidden_format'), context);
    }
    GameLifecycleBus.attach(this.viewModel);
    if (!GameSessionTransfer.restore(this.viewModel)) { this.viewModel.startGame(); }
    this.refreshLayout();
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

  /** 卡牌尺寸与行数随难度变化 */
  refreshLayout(): void {
    this.rowIdx = range(this.viewModel.getRowCount());
    const widthVp: number = this.boardWidthVp > 0 ? this.boardWidthVp : ScreenUtils.windowWidthVp();
    this.cardW = ScreenUtils.calcCellForWidth(widthVp, COLS, 520, 40);
    if (this.boardHeightVp > 0) {
      const rows: number = this.viewModel.getRowCount();
      const byHeight: number = Math.floor((this.boardHeightVp - SpacingTokens.xl - rows * 4) / (rows * 1.15));
      this.cardW = Math.max(1, Math.min(this.cardW, byHeight));
    }
  }

  changeDifficulty(d: GameDifficulty): void {
    this.viewModel.changeDifficulty(d);
    this.refreshLayout();
  }

  getCardBg(idx: number): ResourceColor {
    if (this.viewModel.isMatched(idx)) { return $r('app.color.play_success_background'); }
    if (this.viewModel.isFlipped(idx)) { return $r('app.color.play_cell_background'); }
    return $r('app.color.play_cell_alternate');
  }

  getCardOpacity(idx: number): number {
    if (this.viewModel.isMatched(idx)) { return 0.72; }
    return 1;
  }

  getCardFace(symbol: string): Resource {
    switch (symbol) {
      case 'sun': return $r('app.media.play_memory_sun');
      case 'moon': return $r('app.media.play_memory_moon');
      case 'star': return $r('app.media.play_memory_star');
      case 'heart': return $r('app.media.play_memory_heart');
      case 'clover': return $r('app.media.play_memory_clover');
      case 'bolt': return $r('app.media.play_memory_bolt');
      case 'crown': return $r('app.media.play_memory_crown');
      case 'diamond': return $r('app.media.play_memory_diamond');
      case 'spiral': return $r('app.media.play_memory_spiral');
      case 'leaf': return $r('app.media.play_memory_leaf');
      case 'shell': return $r('app.media.play_memory_shell');
      case 'flame': return $r('app.media.play_memory_flame');
      default: return $r('app.media.play_memory_star');
    }
  }

  @Styles
  pressedFeedback() {
    .opacity(0.72)
    .scale({ x: 0.96, y: 0.96 })
  }

  @Builder
  PageHeader() {
    GameHeader({ gameId: 'memorycard', pathStack: this.pathStack, hasProgress: (): boolean => this.viewModel.hasProgress(),
          gameTitle: $r('app.string.game_memorycard_name'),
          showScore: false,
          difficulty: this.viewModel.difficulty,
          onDifficultyChange: (d: GameDifficulty) => { this.changeDifficulty(d); },
          onBack: () => { this.requestExit(); },
          showPause: false,
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


        Row() {
          Column() {
            Text($r('app.string.memory_pairs_label')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
            Text(this.viewModel.matchedCount + '/' + this.viewModel.getPairCount()).fontSize(FontTokens.sizeHeadline)
              .fontWeight(FontWeight.Bold).fontColor(SemanticColors.successText).id('memory-pairs')
          }.layoutWeight(1).padding(SpacingTokens.sm).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.base)
            .margin({ left: SpacingTokens.base })
          Column() {
            Text($r('app.string.attempts_label')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textTertiary)
            Text('' + this.viewModel.attempts).id('memory-attempts').fontSize(FontTokens.sizeHeadline).fontWeight(FontTokens.weightBold).fontColor(SemanticColors.accent)
          }.layoutWeight(1).padding(8).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.base)
          .alignItems(HorizontalAlign.Center).margin({ left: SpacingTokens.sm })
          Column() {
            Text($r('app.string.puzzle_difficulty_best')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textTertiary)
            Text(this.viewModel.getBestText()).id('memory-level-best').fontSize(FontTokens.sizeHeadline)
              .fontWeight(FontTokens.weightBold).fontColor(SemanticColors.textPrimary)
          }.layoutWeight(1).padding(8).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.base)
          .alignItems(HorizontalAlign.Center).margin({ left: 8, right: 16 })
        }.margin({ top: 12, bottom: 12 })
        if (this.viewModel.unclassifiedScore > 0) {
          Text($r('app.string.puzzle_legacy_score', this.viewModel.unclassifiedScore))
            .fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary).id('memory-legacy-best')
        }

        Column() {
          ForEach(this.rowIdx, (r: number) => {
            Row() {
              ForEach(this.colIdx, (c: number) => {
                Stack() {
                  if (this.viewModel.isFaceUp(r * COLS + c)) {
                    Image(this.getCardFace(this.viewModel.cardEmoji(r * COLS + c)))
                      .id('memory-face-' + (r * COLS + c) + '-' + this.viewModel.cardEmoji(r * COLS + c))
                      .width(this.cardW * 0.7).height(this.cardW * 0.7)
                      .objectFit(ImageFit.Contain)
                    if (this.viewModel.isMatched(r * COLS + c)) {
                      SymbolGlyph($r('sys.symbol.checkmark_circle')).fontSize(FontTokens.sizeBody)
                        .fontColor([SemanticColors.successText]).align(Alignment.TopEnd).margin(SpacingTokens.xs)
                    }
                  } else {
                    Image($r('app.media.play_memory_back'))
                      .width(this.cardW).height(this.cardW * 1.15)
                      .objectFit(ImageFit.Fill)
                  }
                }.width(this.cardW).height(this.cardW * 1.15).margin(2).id('memory-card-' + (r * COLS + c))
                .backgroundColor(this.getCardBg(r * COLS + c))
                .borderRadius(RadiusTokens.base)

                .opacity(this.getCardOpacity(r * COLS + c))
                .accessibilityText(
                  this.viewModel.isFaceUp(r * COLS + c)
                    ? this.a11yCardFlippedFormat.replace('%1$d', '' + (r * COLS + c + 1))
                    : this.a11yCardHiddenFormat.replace('%1$d', '' + (r * COLS + c + 1))
                )
                .stateStyles({ pressed: this.pressedFeedback }).onClick(() => { Haptics.tap(); this.viewModel.flipCard(r * COLS + c); })
              }, (c: number) => c.toString())
            }
          }, (r: number) => r.toString())
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).padding({ bottom: SpacingTokens.xl })
          .backgroundImage($r('app.media.play_memory_board'))
          .backgroundImageSize({ width: '100%', height: '100%' })
          .onAreaChange((oldValue: Area, newValue: Area) => {
            const width: number = parseFloat(newValue.width as string);
            const height: number = parseFloat(newValue.height as string);
            if (Number.isFinite(width) && Number.isFinite(height) && width > 0 && height > 0) {
              this.boardWidthVp = width;
              this.boardHeightVp = height;
              this.refreshLayout();
            }
          })
      }.width('100%').height('100%').padding({ bottom: this.safeArea.bottom })

      if (this.viewModel.status === GameStatus.OVER) {
        GameResultDialog({ shareGameId: 'memorycard',
          symbol: $r('sys.symbol.star_fill'),
          symbolColor: SemanticColors.warning,
          title: $r('app.string.result_all_found'),
          detail: $r('app.string.result_detail_memory_format', this.viewModel.attempts, this.viewModel.bestScore),
          detailColor: SemanticColors.warning,
          showDetail: true,
          primaryText: $r('app.string.result_play_again'),
          onPrimary: () => { this.viewModel.startGame(); },
          showSecondary: true, secondaryText: $r('app.string.action_back'), onSecondary: () => { this.pathStack.pop(); },
          cardStyle: true, celebrate: true
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
    PageDestination({ gameId: 'memorycard', header: () => { this.PageHeader(); }, content: () => { this.PageContent(); } })
  }
}
