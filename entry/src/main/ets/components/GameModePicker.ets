import { FontTokens, SemanticColors, SpacingTokens } from '../common/DesignTokens';
import { GameDataManager } from '../model/GameData';

@ComponentV2
export struct GameModePicker {
  @Param modes: string[] = [];
  @Param selected: string = '';
  @Param best: number = 0;
  @Param hasProgress: boolean = false;
  @Param onChange: (mode: string) => void = () => {};
  label(mode: string): Resource {
    if (mode === 'compare') { return $r('app.string.game_compare_name'); }
    if (mode === 'sequence') { return $r('app.string.game_sequence_name'); }
    if (mode === 'binary') { return $r('app.string.game_binary_name'); }
    if (mode === 'targetsum') { return $r('app.string.game_targetsum_name'); }
    if (mode === 'beatjump') { return $r('app.string.game_beatjump_name'); }
    return mode === 'rhythm' ? $r('app.string.mode_rhythm') : $r('app.string.mode_arithmetic');
  }
  choose(mode: string): void {
    if (mode === this.selected) { return; }
    if (!this.hasProgress) { this.onChange(mode); return; }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.mode_change_title'), message: $r('app.string.game_settings_difficulty_confirm'),
      primaryButton: { value: $r('app.string.settings_cancel'), action: () => {} },
      secondaryButton: { value: $r('app.string.game_settings_change_action'), action: () => { this.onChange(mode); } }
    });
  }
  build() {
    Column({ space: SpacingTokens.sm }) {
      if (this.modes.length > 1) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.modes, (mode: string) => {
            Button(this.label(mode)).margin(SpacingTokens.xs)
              .backgroundColor(this.selected === mode ? SemanticColors.primary : SemanticColors.surface)
              .fontColor(this.selected === mode ? SemanticColors.textOnPrimary : SemanticColors.textPrimary)
              .onClick(() => { this.choose(mode); })
          }, (mode: string) => mode)
        }.width('100%')
        Text($r('app.string.mode_best', this.best)).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
      }
      if (GameDataManager.archivedModeScore(this.selected) > 0) {
        Text($r('app.string.mode_archived_best', GameDataManager.archivedModeScore(this.selected)))
          .fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
      }
    }.width('100%')
  }
}
