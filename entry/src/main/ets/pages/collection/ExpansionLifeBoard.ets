import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { ExpansionArt } from '../../common/ExpansionArt';

@ComponentV2
export struct ExpansionLifeBoard {
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  fishingStatus(): Resource { return [$r('app.string.expansion_cast_hint'), $r('app.string.expansion_wait_bite'), $r('app.string.expansion_hook_now'), $r('app.string.expansion_reel_hint')][this.vm.state.data[0]]; }
  fishSpecies(): Resource {
    const names: Resource[] = [$r('app.string.fishing_species_1'), $r('app.string.fishing_species_2'), $r('app.string.fishing_species_3'),
      $r('app.string.fishing_species_4'), $r('app.string.fishing_species_5'), $r('app.string.fishing_species_6')];
    return names[Math.max(0, this.vm.state.pieces[0].color - 1)];
  }
  hold(event: TouchEvent): void {
    if (event.type === TouchType.Down) { this.vm.setDragging(true); this.vm.tap(1); }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.vm.tap(2); this.vm.setDragging(false); }
  }
  build() {
    Column({ space: SpacingTokens.base }) {
      Stack() {
        Image(ExpansionArt.board('fishing')).width('100%').height('100%').objectFit(ImageFit.Fill).accessibilityLevel('no')
        Image(this.vm.state.data[0] === 2 ? $r('app.media.exp_bite') : this.vm.state.data[0] === 0 ? ExpansionArt.fish(3) : $r('app.media.exp_bobber'))
          .width(62).height(62).objectFit(ImageFit.Contain).accessibilityLevel('no')
          .translate({ x: (this.vm.state.pieces[0].x - 180) * 0.7, y: 30 })
          .scale({ x: this.vm.state.data[0] === 2 ? 1.15 : 1, y: this.vm.state.data[0] === 2 ? 1.15 : 1 })
          .animation({ duration: 180, curve: Curve.FastOutSlowIn })
        Column() {
          Row({ space: SpacingTokens.sm }) {
            Text(this.fishingStatus()).fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Medium)
              .fontColor(this.vm.state.data[0] === 2 ? SemanticColors.warningText : SemanticColors.textPrimary).id('fishing-phase')
            if (this.vm.state.variant === 1 && this.vm.state.data[0] > 0) { Text(this.fishSpecies()).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary) }
          }.padding(SpacingTokens.sm).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.md)
          Blank().layoutWeight(1)
          if (this.vm.state.data[0] === 3) {
            Column({ space: SpacingTokens.sm }) {
              Row({ space: SpacingTokens.sm }) {
                Text($r('app.string.fishing_tension_points', this.vm.state.data[2])).id('fishing-tension')
                  .fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textPrimary).layoutWeight(1)
                Progress({ value: this.vm.state.data[2], total: 100, type: ProgressType.Linear })
                  .color(this.vm.state.data[2] < 25 || this.vm.state.data[2] > 75 ? SemanticColors.warningText : SemanticColors.successText)
                  .layoutWeight(1.25).id('fishing-tension-bar')
              }.width('100%')
              Row({ space: SpacingTokens.sm }) {
                Text($r('app.string.fishing_reel_percent', this.vm.state.data[3].toString() + '%')).id('fishing-reel-percent')
                  .fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textPrimary).layoutWeight(1)
                Progress({ value: this.vm.state.data[3], total: 100, type: ProgressType.Linear })
                  .color(SemanticColors.primary).layoutWeight(1.25).id('fishing-reel-bar')
              }.width('100%')
            }.width('88%').padding(SpacingTokens.sm).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.md)
          }
        }.width('100%').height('100%').padding({ top: SpacingTokens.sm, bottom: SpacingTokens.md }).hitTestBehavior(HitTestMode.None)
      }.width('100%').aspectRatio(1.12).clip(true).backgroundColor(SemanticColors.primaryLight).borderRadius(RadiusTokens.base).id('fishing-water')
      if (this.vm.state.data[0] === 3) {
        Button($r('app.string.expansion_reel_hold')).width('100%').height($r('app.float.expansion_control_height')).id('fishing-reel')
          .onTouch((event: TouchEvent) => { this.hold(event); })
      } else {
        Button(this.vm.state.data[0] === 0 ? $r('app.string.expansion_cast') : $r('app.string.expansion_hook_fish')).enabled(this.vm.state.data[0] !== 1)
          .width('100%').height($r('app.float.expansion_control_height')).id(this.vm.state.data[0] === 0 ? 'fishing-cast' : 'fishing-hook')
          .onClick(() => { this.vm.tap(0); })
      }
    }.width('100%')
  }
}
