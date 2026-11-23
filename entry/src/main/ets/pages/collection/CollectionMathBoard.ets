import { FontTokens, RadiusTokens, SemanticColors, SpacingTokens } from '../../common/DesignTokens';
import { CollectionArt } from '../../common/CollectionArt';
import { MATH_MODES } from '../../common/GameModes';
import { GameDataManager } from '../../model/GameData';
import { CollectionViewModel } from '../../viewmodel/CollectionViewModel';

const MODE_LABELS: Resource[] = [$r('app.string.mode_arithmetic'), $r('app.string.math_short_compare'),
  $r('app.string.math_short_sequence'), $r('app.string.math_short_binary'), $r('app.string.math_short_sum')];

@ComponentV2
export struct CollectionMathBoard {
  @Param @Require vm: CollectionViewModel;

  selectMode(mode: string): void {
    if (this.vm.modeId === mode) { return; }
    if (this.vm.state.round === 0) { this.vm.changeMode(mode); return; }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.mode_change_title'), message: $r('app.string.math_mode_restart'),
      primaryButton: { value: $r('app.string.settings_cancel'), action: () => {} },
      secondaryButton: { value: $r('app.string.game_settings_change_action'), action: () => { this.vm.changeMode(mode); } }
    });
  }

  @Builder
  Question() {
    Column({ space: SpacingTokens.md }) {
      if (this.vm.modeId === 'binary') {
        Text($r('app.string.math_binary_hint')).fontColor(SemanticColors.textSecondary).fontSize(FontTokens.sizeBody)
        Text(this.vm.state.prompt.split('₂')[0]).fontFamily('monospace').letterSpacing(3)
          .fontSize(FontTokens.sizeDisplay).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary).id('math-binary')
      } else if (this.vm.modeId === 'sequence') {
        Row({ space: SpacingTokens.xs }) {
          ForEach(this.vm.state.target, (term: number) => {
            Text(term.toString()).layoutWeight(1).textAlign(TextAlign.Center).fontSize(FontTokens.sizeSubtitle)
              .fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary).backgroundColor(SemanticColors.surfaceHover)
              .padding({ top: SpacingTokens.sm, bottom: SpacingTokens.sm }).borderRadius(RadiusTokens.sm)
          }, (term: number, i: number) => i + '-' + term)
          Text('?').layoutWeight(1).textAlign(TextAlign.Center).fontSize(FontTokens.sizeSubtitle)
            .fontWeight(FontWeight.Bold).fontColor(SemanticColors.primary).backgroundColor(SemanticColors.selectionSurface)
            .padding({ top: SpacingTokens.sm, bottom: SpacingTokens.sm }).borderRadius(RadiusTokens.sm)
        }.width('100%')
      } else if (this.vm.modeId === 'compare' || this.vm.modeId === 'targetsum') {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Text(this.vm.state.prompt.split('?')[0].trim()).fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary)
          Text('?').fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold).fontColor(SemanticColors.primary)
            .backgroundColor(SemanticColors.selectionSurface).padding({ left: SpacingTokens.md, right: SpacingTokens.md })
            .margin(SpacingTokens.xs).borderRadius(RadiusTokens.sm)
          Text((this.vm.state.prompt.split('?')[1] ?? '').trim()).fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary)
        }.width('100%')
      } else {
        Text(this.vm.state.prompt).fontSize(FontTokens.sizeDisplay).fontWeight(FontWeight.Bold)
          .fontColor(SemanticColors.textPrimary).textAlign(TextAlign.Center)
      }
    }.width('100%').constraintSize({ minHeight: $r('app.float.collection_art_question_height') })
      .justifyContent(FlexAlign.Center).padding(SpacingTokens.base).backgroundColor(SemanticColors.surface)
      .backgroundImage(CollectionArt.question(this.vm.modeId)).backgroundImageSize({ width: '100%', height: '100%' })
      .borderRadius(RadiusTokens.lg).id('math-question')
  }

  @Builder
  Answer(index: number) {
    Button(this.vm.modeId === 'compare' ? ['＜', '＝', '＞'][index] : this.vm.state.choices[index].toString())
      .type(ButtonType.Normal).layoutWeight(1).height($r('app.float.expansion_control_height'))
      .fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold)
      .fontColor(SemanticColors.primary).backgroundColor(SemanticColors.selectionSurface)
      .borderRadius(RadiusTokens.md).id('math-choice-' + index).onClick(() => { this.vm.choose(index); })
  }

  build() {
    Column({ space: SpacingTokens.base }) {
      Row({ space: SpacingTokens.xs }) {
        ForEach(MATH_MODES, (mode: string, index: number) => {
          Button(MODE_LABELS[index]).type(ButtonType.Normal).layoutWeight(1).height($r('app.float.home_action_min_height'))
            .padding({ left: SpacingTokens.xs, right: SpacingTokens.xs }).fontSize(FontTokens.sizeBodySmall)
            .fontColor(this.vm.modeId === mode ? SemanticColors.textOnPrimary : SemanticColors.textPrimary)
            .backgroundColor(this.vm.modeId === mode ? SemanticColors.primary : SemanticColors.surface)
            .borderRadius(RadiusTokens.sm).id('math-mode-' + mode).onClick(() => { this.selectMode(mode); })
        }, (mode: string) => mode)
      }.width('100%')
      Row({ space: SpacingTokens.sm }) {
        Text($r('app.string.collection_round', Math.min(10, this.vm.state.round + 1), this.vm.state.score))
          .layoutWeight(1).fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Bold).fontColor(SemanticColors.textPrimary).id('math-round')
        Text($r('app.string.mode_best', this.vm.modeHighScore)).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
      }.width('100%')
      if (GameDataManager.archivedModeScore(this.vm.modeId) > 0) {
        Text($r('app.string.mode_archived_best', GameDataManager.archivedModeScore(this.vm.modeId)))
          .fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
      }
      this.Question()
      Row({ space: SpacingTokens.sm }) {
        this.Answer(0)
        this.Answer(1)
        if (this.vm.modeId === 'compare') { this.Answer(2) }
      }.width('100%')
      if (this.vm.modeId !== 'compare') {
        Row({ space: SpacingTokens.sm }) {
          this.Answer(2)
          this.Answer(3)
        }.width('100%')
      }
      if (this.vm.feedback.length > 0) {
        Text(this.vm.lastCorrect ? $r('app.string.collection_correct', this.vm.feedback) : $r('app.string.collection_wrong', this.vm.feedback))
          .fontSize(FontTokens.sizeBody).fontColor(this.vm.lastCorrect ? SemanticColors.successText : SemanticColors.warningText).id('math-feedback')
      }
    }.width('100%')
  }
}
