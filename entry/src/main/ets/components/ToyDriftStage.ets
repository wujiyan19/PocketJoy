import { ExpansionViewModel } from '../viewmodel/ExpansionViewModel';
import { DriftLevels } from '../model/game/ToyLevelRules';
import { FontTokens, RadiusTokens, SemanticColors, SpacingTokens } from '../common/DesignTokens';

@ComponentV2
export struct ToyDriftStage {
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Param heightLimit: number = 460;
  @Local availableWidth: number = 320;
  @Local widthVp: number = 320;
  viewScale(): number { return this.widthVp / 360; }
  center(y: number): number { return DriftLevels.center(this.vm.state, this.vm.state.time + (390 - y) / 100); }
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
        Image($r('app.media.toy_drift_car')).width(30 * this.viewScale()).height(50 * this.viewScale()).objectFit(ImageFit.Contain)
          .rotate({ angle: (this.vm.state.pieces[0]?.vx ?? 1) > 0 ? 12 : -12 })
          .translate({ x: (this.carX() - 15) * this.viewScale(), y: 365 * this.viewScale() })
          .id('toy-drift-car').accessibilityText($r('app.string.toy_drift_car')).hitTestBehavior(HitTestMode.None)
      }.width(Math.min(this.availableWidth, this.heightLimit * 360 / 460)).aspectRatio(360 / 460)
        .backgroundColor($r('app.color.toy_drift_grass')).borderRadius(RadiusTokens.lg).clip(true).id('toy-drift-board')
        .onAreaChange((oldArea: Area, area: Area) => { this.widthVp = Number(area.width); })
    }.width('100%').onAreaChange((oldArea: Area, area: Area) => { this.availableWidth = Number(area.width); })
  }
}
