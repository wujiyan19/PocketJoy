import { ExpansionViewModel } from '../viewmodel/ExpansionViewModel';
import { DriftLevels } from '../model/game/ToyLevelRules';
import { FontTokens, RadiusTokens, SemanticColors, SpacingTokens } from '../common/DesignTokens';
import { GameBoardArt } from './GameBoardArt';

@ComponentV2
export struct ToyDriftStage {
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Param heightLimit: number = 460;
  @Local availableWidth: number = 320;
  @Local widthVp: number = 320;
  viewScale(): number { return this.widthVp / 360; }
  center(y: number): number { return DriftLevels.center(this.vm.state, this.vm.state.time + (390 - y) / 100); }
  @Computed get nextBendY(): number {
    for (let y: number = 310; y >= 34; y -= 12) {
      if (Math.abs(this.center(y - 28) - this.center(y + 28)) >= 4) { return y; }
    }
    return -1;
  }
  @Computed get bendSide(): number {
    return this.nextBendY >= 0 && this.center(this.nextBendY - 28) > this.center(this.nextBendY + 28) ? 1 : -1;
  }
  edge(side: number, extra: number = 0): number[][] {
    const points: number[][] = [];
    for (let i: number = 0; i <= 50; i++) {
      const y: number = i * 9.2;
      points.push([(this.center(y) + side * (DriftLevels.halfWidth(this.vm.state) + extra)) * this.viewScale(), y * this.viewScale()]);
    }
    return points;
  }
  road(extra: number): number[][] { return this.edge(-1, extra).concat(this.edge(1, extra).reverse()); }
  carX(): number { return this.vm.state.pieces[0]?.x ?? 180; }
  build() {
    Column({ space: SpacingTokens.sm }) {
      Text($r('app.string.toy_drift_hint')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
      Stack({ alignContent: Alignment.TopStart }) {
        GameBoardArt($r('app.media.exp_board_drift'))
        Polygon().width('100%').height('100%').points(this.road(7)).fill($r('app.color.toy_drift_shoulder')).hitTestBehavior(HitTestMode.None)
        Polygon().width('100%').height('100%').points(this.road(0)).fill($r('app.color.toy_drift_road')).hitTestBehavior(HitTestMode.None)
        Polyline().width('100%').height('100%').points(this.edge(-1)).fill(Color.Transparent)
          .stroke($r('app.color.toy_drift_edge')).strokeWidth(2 * this.viewScale()).hitTestBehavior(HitTestMode.None)
        Polyline().width('100%').height('100%').points(this.edge(1)).fill(Color.Transparent)
          .stroke($r('app.color.toy_drift_edge')).strokeWidth(2 * this.viewScale()).hitTestBehavior(HitTestMode.None)
        Polyline().width('100%').height('100%').points(this.edge(0)).fill(Color.Transparent)
          .stroke($r('app.color.toy_drift_marking')).strokeWidth(2 * this.viewScale())
          .strokeDashArray([8 * this.viewScale(), 14 * this.viewScale()])
          .strokeDashOffset(-this.vm.state.time * 100 * this.viewScale()).hitTestBehavior(HitTestMode.None)
        if (this.nextBendY >= 0) {
          Text(this.bendSide > 0 ? '→' : '←').fontSize(FontTokens.sizeSubtitle).fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center).width(28 * this.viewScale()).height(24 * this.viewScale())
            .fontColor($r('app.color.toy_drift_sign_ink')).backgroundColor($r('app.color.toy_drift_sign_face'))
            .border({ width: 1, color: $r('app.color.toy_drift_sign_ink') }).borderRadius(RadiusTokens.sm)
            .translate({ x: (this.center(this.nextBendY) + this.bendSide * (DriftLevels.halfWidth(this.vm.state) - 19) - 14) * this.viewScale(),
              y: (this.nextBendY - 12) * this.viewScale() }).id(this.bendSide > 0 ? 'drift-bend-right' : 'drift-bend-left')
            .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        }
        Image($r('app.media.toy_drift_car')).width(30 * this.viewScale()).height(50 * this.viewScale()).objectFit(ImageFit.Contain)
          .rotate({ angle: (this.vm.state.pieces[0]?.vx ?? 1) > 0 ? 12 : -12 })
          .translate({ x: (this.carX() - 15) * this.viewScale(), y: 365 * this.viewScale() })
          .id('toy-drift-car').accessibilityText($r('app.string.toy_drift_car')).hitTestBehavior(HitTestMode.None)
        Text((this.vm.state.pieces[0]?.vx ?? 1) > 0 ? '→' : '←').fontSize(FontTokens.sizeBodyLarge)
          .fontWeight(FontWeight.Bold).fontColor(Color.White).id('drift-direction')
          .translate({ x: (this.carX() - 7) * this.viewScale(), y: 344 * this.viewScale() }).hitTestBehavior(HitTestMode.None)
      }.width(Math.min(this.availableWidth, this.heightLimit * 360 / 460)).aspectRatio(360 / 460)
        .backgroundColor($r('app.color.toy_drift_grass')).borderRadius(RadiusTokens.lg).clip(true).id('toy-drift-board')
        .onClick(() => { if (this.vm.state.phase !== 0) { this.vm.tap(0); } })
        .onAreaChange((oldArea: Area, area: Area) => { this.widthVp = Number(area.width); })
    }.width('100%').onAreaChange((oldArea: Area, area: Area) => { this.availableWidth = Number(area.width); })
  }
}
