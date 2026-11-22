import { FontTokens, RadiusTokens, SemanticColors, SpacingTokens } from '../../common/DesignTokens';
import { Haptics } from '../../common/Haptics';
import { resolveString } from '../../common/I18nUtils';
import { GameLifecycleBus } from '../../common/GameLifecycleBus';
import { range } from '../../common/Range';
import { SettingsChoice } from '../../components/SettingsChoice';
import { SokobanBoard } from '../../components/SokobanBoard';
import { WarehouseTile, warehouseGoalsFilled } from '../../model/game/ExpansionAdventure';
import { SOKOBAN_LEVELS } from '../../model/game/SokobanLevels';
import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';

@ComponentV2
export struct SokobanPlayArea {
  @Param @Require vm: ExpansionViewModel;
  @Local pickerVisible: boolean = false;
  @Local browseCampaign: boolean = true;
  @Local boardAreaWidth: number = 0;
  @Local boardAreaHeight: number = 0;

  @Computed get boardSide(): number {
    const minSide: number = this.vm.state.cols * (FontTokens.sizeBodyLarge + SpacingTokens.sm);
    return Math.min(this.boardAreaWidth, Math.max(minSide, this.boardAreaHeight));
  }

  @Computed get legend(): Resource {
    const star: boolean = this.vm.state.board.includes(WarehouseTile.StarGoal);
    const arrow: boolean = this.vm.state.board.some((cell: number) => cell >= WarehouseTile.Up);
    if (star && arrow) { return $r('app.string.sokoban_legend_combined'); }
    if (star) { return $r('app.string.sokoban_legend_star'); }
    return arrow ? $r('app.string.sokoban_legend_arrow') : $r('app.string.sokoban_swipe_hint');
  }

  selectBoard(level: number): void {
    if (level === this.vm.sokobanLevel) { this.pickerVisible = false; return; }
    const change = (): void => {
      this.vm.selectSokobanLevel(level);
      this.pickerVisible = false;
    };
    if (!this.vm.hasProgress()) { change(); return; }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.sokoban_select_level'), message: $r('app.string.sokoban_change_board_confirm'),
      primaryButton: { value: $r('app.string.settings_cancel'), action: () => {} },
      secondaryButton: { value: $r('app.string.game_settings_change_action'), action: change }
    });
  }

  restart(): void {
    if (!this.vm.hasProgress()) { this.vm.startGame(); return; }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.header_restart'), message: $r('app.string.game_settings_restart_confirm'),
      primaryButton: { value: $r('app.string.settings_cancel'), action: () => {} },
      secondaryButton: { value: $r('app.string.sokoban_controls_restart'), action: () => { this.vm.startGame(); } }
    });
  }

  aboutToDisappear(): void {
    if (this.pickerVisible) { GameLifecycleBus.setSettingsVisible('sokoban', false); }
  }

  @Builder
  LevelButton(level: number) {
    Button() {
      Row({ space: SpacingTokens.xs }) {
        Text(level.toString()).fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Medium)
          .fontColor(this.vm.sokobanLevel === level ? SemanticColors.primary : SemanticColors.textPrimary)
        if (level <= this.vm.sokobanCompleted) {
          SymbolGlyph($r('sys.symbol.checkmark')).fontSize(FontTokens.sizeCaption).fontColor([SemanticColors.successText])
        } else if (level > this.vm.sokobanUnlocked()) {
          SymbolGlyph($r('sys.symbol.lock')).fontSize(FontTokens.sizeCaption).fontColor([SemanticColors.textSecondary])
        }
      }.justifyContent(FlexAlign.Center)
    }.type(ButtonType.Normal).borderRadius(RadiusTokens.md)
      .layoutWeight(1).height($r('app.float.expansion_control_height'))
      .backgroundColor(this.vm.sokobanLevel === level ? SemanticColors.selectionSurface : SemanticColors.surfaceHover)
      .border({ width: level === this.vm.sokobanLevel ? 2 : 0, color: SemanticColors.primary })
      .enabled(level <= this.vm.sokobanUnlocked()).id('sokoban-level-' + level)
      .accessibilityText($r('app.string.sokoban_level_number', level))
      .accessibilityDescription(resolveString(this.vm.sokobanLevel === level ? $r('app.string.sokoban_level_current') :
        level <= this.vm.sokobanCompleted ? $r('app.string.sokoban_level_completed') :
          level > this.vm.sokobanUnlocked() ? $r('app.string.sokoban_level_locked') : '', this.getUIContext().getHostContext()))
      .onClick(() => { this.selectBoard(level); })
  }

  @Builder
  Picker() {
    Column({ space: SpacingTokens.md }) {
      Row({ space: SpacingTokens.md }) {
        Text($r('app.string.sokoban_select_level')).layoutWeight(1).fontSize(FontTokens.sizeTitle)
          .fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary)
        Button() { SymbolGlyph($r('sys.symbol.xmark')).fontSize(FontTokens.sizeBodyLarge).fontColor([SemanticColors.textSecondary]) }
          .type(ButtonType.Circle).width($r('app.float.home_action_min_height')).height($r('app.float.home_action_min_height'))
          .backgroundColor(SemanticColors.surfaceHover).id('sokoban-picker-close')
          .accessibilityText($r('app.string.game_settings_return')).onClick(() => { this.pickerVisible = false; })
      }.width('100%')
      Row({ space: SpacingTokens.sm }) {
        SettingsChoice({ label: $r('app.string.sokoban_campaign'), selected: this.browseCampaign,
          onChoose: () => { this.browseCampaign = true; } }).id('sokoban-mode-campaign')
        SettingsChoice({ label: $r('app.string.sokoban_random'), selected: !this.browseCampaign,
          onChoose: () => { this.browseCampaign = false; } }).id('sokoban-mode-random')
      }.width('100%')
      Scroll() {
        Column({ space: SpacingTokens.sm }) {
          if (this.browseCampaign) {
            Text($r('app.string.sokoban_level_progress', this.vm.sokobanCompleted, SOKOBAN_LEVELS.length))
              .alignSelf(ItemAlign.Start).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textSecondary)
            ForEach(range(Math.ceil(SOKOBAN_LEVELS.length / 4)), (row: number) => {
              Row({ space: SpacingTokens.sm }) {
                ForEach(range(Math.min(4, SOKOBAN_LEVELS.length - row * 4)), (col: number) => {
                  this.LevelButton(row * 4 + col + 1)
                }, (col: number) => col.toString())
              }.width('100%')
            }, (row: number) => row.toString())
          } else {
            Button(this.vm.sokobanLevel === 0 ? $r('app.string.game_settings_return') : $r('app.string.sokoban_random_play'))
              .width('100%').height($r('app.float.expansion_control_height')).id('sokoban-random-play')
              .onClick(() => { this.selectBoard(0); })
          }
        }.width('100%').padding({ bottom: SpacingTokens.xl })
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Auto)
    }.width('100%').height('100%').padding({ left: SpacingTokens.base, right: SpacingTokens.base, top: SpacingTokens.xs })
  }

  @Builder
  Direction(symbol: Resource, label: Resource, name: string, direction: number) {
    Button() { SymbolGlyph(symbol).fontSize($r('app.float.home_header_action_icon_size')).fontColor([SemanticColors.primary]) }
      .type(ButtonType.Normal).borderRadius(RadiusTokens.md).backgroundColor(SemanticColors.selectionSurface)
      .width($r('app.float.home_action_min_height')).height($r('app.float.home_action_min_height'))
      .accessibilityText(label).id('control-pad-' + name).onClick(() => { Haptics.tap(); this.vm.tap(direction); })
  }

  @Builder
  SideAction(symbol: Resource, label: Resource, id: string, isUndo: boolean, action: () => void) {
    Button() {
      Column({ space: SpacingTokens.xs }) {
        SymbolGlyph(symbol).fontSize(FontTokens.sizeSubtitle).fontColor([SemanticColors.textSecondary])
        Text(label).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
      }
    }.type(ButtonType.Normal).backgroundColor(Color.Transparent).enabled(!isUndo || this.vm.canUndo).id(id)
      .layoutWeight(1).height($r('app.float.expansion_control_height')).accessibilityText(label).onClick(action)
  }

  build() {
    Column({ space: SpacingTokens.sm }) {
      Row({ space: SpacingTokens.sm }) {
        Button() {
          Column({ space: SpacingTokens.xs }) {
            Text($r('app.string.sokoban_board_status', warehouseGoalsFilled(this.vm.state), this.vm.state.goal, this.vm.state.moves))
              .fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Medium).fontColor(SemanticColors.textPrimary).id('sokoban-status')
            Row({ space: SpacingTokens.xs }) {
              SymbolGlyph($r('sys.symbol.questionmark_circle')).fontSize(FontTokens.sizeCaption)
                .fontColor([SemanticColors.textSecondary]).accessibilityLevel('no')
              Text(this.legend).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary).maxLines(1).id('sokoban-legend')
            }
          }.alignItems(HorizontalAlign.Start).width('100%')
        }.type(ButtonType.Normal).layoutWeight(1).height($r('app.float.expansion_control_height'))
          .padding(0).backgroundColor(Color.Transparent).accessibilityDescription($r('app.string.game_settings_rules'))
          .onClick(() => {
            this.getUIContext().showAlertDialog({ title: $r('app.string.game_settings_rules'), message: $r('app.string.game_sokoban_rules'),
              confirm: { value: $r('app.string.game_settings_return'), action: () => {} } });
          })
        Button($r('app.string.sokoban_select_level')).height($r('app.float.home_action_min_height'))
          .backgroundColor(SemanticColors.surfaceHover).fontColor(SemanticColors.primary).fontSize(FontTokens.sizeBody)
          .id('sokoban-picker-open').onClick(() => {
            this.browseCampaign = this.vm.sokobanLevel > 0;
            GameLifecycleBus.setSettingsVisible('sokoban', true);
            this.pickerVisible = true;
          }).bindSheet($$this.pickerVisible, this.Picker, {
            preferType: SheetType.BOTTOM, height: SheetSize.MEDIUM, detents: [SheetSize.MEDIUM, SheetSize.LARGE],
            showClose: false, dragBar: true, backgroundColor: SemanticColors.surface,
            onDisappear: () => { this.pickerVisible = false; GameLifecycleBus.setSettingsVisible('sokoban', false); }
          })
      }.width('100%')
      Scroll() {
        Stack() {
          SokobanBoard({ vm: this.vm, boardWidth: this.boardSide })
        }.width('100%').height(Math.max(this.boardAreaHeight, this.boardSide))
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
        .enableScrollInteraction(this.boardSide > this.boardAreaHeight)
        .onAreaChange((oldArea: Area, area: Area) => {
          this.boardAreaWidth = Number(area.width);
          this.boardAreaHeight = Number(area.height);
        })
      Row({ space: SpacingTokens.sm }) {
        this.SideAction($r('sys.symbol.arrow_clockwise'), $r('app.string.sokoban_controls_restart'), 'sokoban-restart', false,
          () => { this.restart(); })
        Column({ space: SpacingTokens.xs }) {
          this.Direction($r('sys.symbol.arrow_up'), $r('app.string.a11y_direction_up'), 'up', 0)
          Row({ space: SpacingTokens.xs }) {
            this.Direction($r('sys.symbol.arrow_left'), $r('app.string.a11y_direction_left'), 'left', 3)
            Column().width($r('app.float.home_action_min_height')).height($r('app.float.home_action_min_height')).accessibilityLevel('no')
            this.Direction($r('sys.symbol.arrow_right'), $r('app.string.a11y_direction_right'), 'right', 1)
          }
          this.Direction($r('sys.symbol.arrow_down'), $r('app.string.a11y_direction_down'), 'down', 2)
        }
        this.SideAction($r('sys.symbol.arrowshape_turn_up_left'), $r('app.string.sokoban_controls_undo'), 'sokoban-undo', true,
          () => { this.vm.undo(); })
      }.width('100%').padding({ bottom: SpacingTokens.sm })
    }.width('100%').height('100%').constraintSize({ maxWidth: $r('app.float.expansion_board_max') })
      .padding({ left: SpacingTokens.base, right: SpacingTokens.base })
  }
}
