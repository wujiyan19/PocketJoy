import { GameColorCue } from '../../common/GameColorCue';
import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ExpansionRenderPiece } from '../../viewmodel/ExpansionRenderPiece';
import { ExpansionPiece } from '../../model/game/ExpansionState';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { range } from '../../common/Range';
import { ExpansionArt } from '../../common/ExpansionArt';
import { ExpansionBackdrop } from './ExpansionBackdrop';

@ComponentV2
export struct ExpansionSortingBoard {
  @Param gameId: string = '';
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Local arenaWidth: number = 320;
  color(value: number): Resource {
    const palette: Resource[] = [$r('app.color.expansion_color_1'), $r('app.color.expansion_color_2'), $r('app.color.expansion_color_3'),
      $r('app.color.expansion_color_4'), $r('app.color.expansion_color_5'), $r('app.color.expansion_color_6')];
    return value <= 0 ? SemanticColors.surface : palette[(value - 1) % 6];
  }
  symbol(value: number): string { return GameColorCue.symbol(value); }
  colorName(value: number): Resource {
    const names: Resource[] = [$r('app.string.expansion_color_1'), $r('app.string.expansion_color_2'), $r('app.string.expansion_color_3'),
      $r('app.string.expansion_color_4'), $r('app.string.expansion_color_5'), $r('app.string.expansion_color_6')];
    return value <= 0 ? $r('app.string.expansion_empty') : names[(value - 1) % 6];
  }
  arenaScale(): number { return this.arenaWidth / 360; }
  point(id: number): number[] { const p: ExpansionPiece = this.vm.state.pieces[id]; return [p.x * this.arenaScale(), p.y * this.arenaScale()]; }
  measure(area: Area): void { const width: number = Number(area.width); if (Number.isFinite(width) && width > 0) { this.arenaWidth = width; } }
  touch(event: TouchEvent): void {
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.vm.setDragging(false); return; }
    if (event.touches.length === 0) { return; }
    const x: number = event.touches[0].x / this.arenaScale(); const y: number = event.touches[0].y / this.arenaScale();
    if (event.type === TouchType.Down) {
      let nearest: number = Math.max(32, 24 / this.arenaScale());
      let node: ExpansionPiece | undefined = undefined;
      for (const piece of this.vm.state.pieces) {
        const distance: number = Math.hypot(piece.x - x, piece.y - y);
        if (distance < nearest) { nearest = distance; node = piece; }
      }
      if (node) { this.vm.setDragging(false); this.vm.tap(node.id); this.vm.setDragging(true); }
    } else if (event.type === TouchType.Move && this.vm.dragging) { this.vm.aim(x, y); }
  }
  build() {
    Column({ space: SpacingTokens.base }) {
      if (this.gameId === 'buscolor') { this.Buses() }
      if (this.gameId === 'untangle') { this.Knots() }
    }.width('100%').padding(SpacingTokens.sm).backgroundImage(this.gameId === 'buscolor' ? ExpansionArt.board(this.gameId) : '')
      .backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
  }
  @Builder
  Bus(index: number, parked: boolean) {
    Column({ space: SpacingTokens.xs }) {
      Row({ space: SpacingTokens.xs }) {
        Image(ExpansionArt.bus(this.vm.state.pieces[parked ? this.vm.state.tray[index] : index].color - 1))
          .width(40).height(32).objectFit(ImageFit.Contain)
        Text(this.symbol(this.vm.state.pieces[parked ? this.vm.state.tray[index] : index].color))
          .fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeBodyLarge)
      }
      if (parked) {
        Row({ space: SpacingTokens.xs }) {
          ForEach(range(3), (seat: number) => {
            Text(seat < this.vm.state.pieces[this.vm.state.tray[index]].w ? '●' : '○')
              .fontColor(this.color(this.vm.state.pieces[this.vm.state.tray[index]].color)).fontSize(FontTokens.sizeCaption)
          }, (seat: number) => seat.toString())
        }
      }
    }.width('100%').padding(SpacingTokens.xs).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.sm)
  }
  @Builder
  Buses() {
    Column({ space: SpacingTokens.sm }) {
      Text($r('app.string.expansion_passenger_queue')).fontColor(SemanticColors.textSecondary)
      Row({ space: SpacingTokens.sm }) {
        ForEach(range(Math.min(9, this.vm.state.board.length - this.vm.state.cursor)), (index: number) => {
          Column({ space: SpacingTokens.xs }) {
            Image(ExpansionArt.person(this.vm.state.board[this.vm.state.cursor + index] - 1)).objectFit(ImageFit.Contain).height(30).width('100%')
            Text(this.symbol(this.vm.state.board[this.vm.state.cursor + index])).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textPrimary)
          }.layoutWeight(1).accessibilityGroup(true)
            .accessibilityText(this.colorName(this.vm.state.board[this.vm.state.cursor + index]))
        }, (index: number) => index.toString())
      }.width('100%').padding(SpacingTokens.sm).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.sm)
      Text($r('app.string.expansion_parking_slots', this.vm.state.tray.length)).fontColor(SemanticColors.textSecondary)
      Row({ space: SpacingTokens.sm }) {
        ForEach(range(3), (slot: number) => {
          Column() {
            if (slot < this.vm.state.tray.length) { this.Bus(slot, true) }
            else { Text('○').fontColor(SemanticColors.textSecondary).height(58).width('100%').textAlign(TextAlign.Center) }
          }.layoutWeight(1).border({ width: 1, color: $r('app.color.bus_parking_border') }).borderRadius(RadiusTokens.sm)
        }, (slot: number) => slot.toString())
      }.width('100%')
      if (this.vm.state.tray.length === 3) { Text($r('app.string.expansion_bus_stuck')).fontColor(SemanticColors.warningText) }
      Row({ space: SpacingTokens.sm }) {
        ForEach(range(3), (lane: number) => {
          Column({ space: SpacingTokens.sm }) {
            Text($r('app.string.expansion_key', lane + 1)).fontColor(SemanticColors.textSecondary)
            ForEach(range(4), (pos: number) => {
              if (pos >= this.vm.state.data[lane]) {
                Button({ type: ButtonType.Normal }) { this.Bus(lane * 4 + pos, false) }
                  .width('100%').padding(0).backgroundColor(SemanticColors.surface)
                  .borderRadius(RadiusTokens.sm).border({ width: pos === this.vm.state.data[lane] ? 2 : 0, color: SemanticColors.primary })
                  .id('bus-lane-' + lane + '-' + pos)
                  .enabled(pos === this.vm.state.data[lane] && this.vm.state.tray.length < 3)
                  .accessibilityText($r('app.string.expansion_launch_bus', lane + 1, pos + 1))
                  .onClick(() => { this.vm.tap(lane); })
              }
            }, (pos: number) => pos.toString())
          }.layoutWeight(1)
        }, (lane: number) => lane.toString())
      }.width('100%').alignItems(VerticalAlign.Top)
    }.width('100%')
  }
  knotDiameter(point: ExpansionPiece): number {
    let diameter: number = 42;
    for (const other of this.vm.state.pieces) {
      if (other.id !== point.id) { diameter = Math.min(diameter, Math.hypot(other.x - point.x, other.y - point.y)); }
    }
    return Math.max(36, diameter);
  }
  @Builder
  Knots() {
    Stack({ alignContent: Alignment.TopStart }) {
      ExpansionBackdrop(this.gameId)
      ForEach(range(this.vm.state.board.length / 2), (edge: number) => {
        Line().width('100%').height('100%').startPoint(this.point(this.vm.state.board[edge * 2])).endPoint(this.point(this.vm.state.board[edge * 2 + 1]))
          .strokeWidth(this.vm.dragging && (this.vm.state.board[edge * 2] === this.vm.state.selected ||
            this.vm.state.board[edge * 2 + 1] === this.vm.state.selected) ? 6 : 3)
          .stroke(this.vm.crossingEdges().includes(edge * 2) ? SemanticColors.warning : SemanticColors.primary)
          .hitTestBehavior(HitTestMode.None)
      }, (edge: number) => edge.toString())
      ForEach(this.vm.worldPieces, (rendered: ExpansionRenderPiece) => {
        Stack() {
          Text((rendered.id + 1).toString()).width(this.knotDiameter(rendered.piece) * this.arenaScale()).aspectRatio(1).textAlign(TextAlign.Center)
            .fontSize(Math.max(FontTokens.sizeBodyLarge, Math.min(FontTokens.sizeTitle, SpacingTokens.lg * this.arenaScale())))
            .fontWeight(FontWeight.Bold).fontColor(SemanticColors.textOnPrimary).backgroundColor(SemanticColors.primary)
            .borderRadius(RadiusTokens.full).border({ width: this.vm.state.selected === rendered.id ? 3 : 1, color: this.vm.state.selected === rendered.id ? SemanticColors.warning : SemanticColors.surface })
            .id('knot-node-' + rendered.id).accessibilityText($r('app.string.expansion_node', rendered.id + 1))
        }.width(42 * this.arenaScale()).height(42 * this.arenaScale())
          .translate({ x: (rendered.piece.x - 21) * this.arenaScale(), y: (rendered.piece.y - 21) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
      }, (rendered: ExpansionRenderPiece) => rendered.id.toString())
    }.width('100%').aspectRatio(360 / 460).backgroundColor(SemanticColors.boardBg).borderRadius(RadiusTokens.base).clip(true)
      .id('knot-board').onAreaChange((oldArea: Area, area: Area) => { this.measure(area); }).onTouch((event: TouchEvent) => { this.touch(event); })
  }
}
