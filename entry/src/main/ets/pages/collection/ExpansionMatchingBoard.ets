import { GameColorCue } from '../../common/GameColorCue';
import { resolveString } from '../../common/I18nUtils';
import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ExpansionRenderPiece } from '../../viewmodel/ExpansionRenderPiece';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { range } from '../../common/Range';
import { ExpansionArt } from '../../common/ExpansionArt';
import { GameArtTile } from '../../components/GameArtTile';

@ComponentV2
export struct ExpansionMatchingBoard {
  @Param gameId: string = '';
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Local boardWidth: number = 320;
  color(value: number): Resource {
    const palette: Resource[] = [$r('app.color.expansion_color_1'), $r('app.color.expansion_color_2'), $r('app.color.expansion_color_3'),
      $r('app.color.expansion_color_4'), $r('app.color.expansion_color_5'), $r('app.color.expansion_color_6')];
    return value <= 0 ? SemanticColors.surface : palette[(value - 1) % 6];
  }
  linkTileFace(value: number): Resource {
    const faces: Resource[] = [$r('app.color.linktile_face_1'), $r('app.color.linktile_face_2'), $r('app.color.linktile_face_3'),
      $r('app.color.linktile_face_4'), $r('app.color.linktile_face_5'), $r('app.color.linktile_face_6')];
    return value > 0 ? faces[value - 1] : SemanticColors.surface;
  }
  symbol(value: number): string { return GameColorCue.symbol(value); }
  measure(area: Area): void { const width: number = Number(area.width); if (Number.isFinite(width) && width > 0) { this.boardWidth = width; } }
  unit(): number { return this.boardWidth / (this.gameId === 'linktiles' ? 8 : 6); }
  pathPoint(cell: number): number[] { return [(cell % 8 + 0.5) * this.unit(), (Math.floor(cell / 8) + 0.5) * this.unit()]; }
  build() {
    Column({ space: SpacingTokens.base }) {
      if (this.gameId === 'mahjongsolitaire') { this.Mahjong() }
      else if (this.gameId === 'groupclear') {
        Stack() { this.Board() }.width('100%').id('groupclear-board')
      } else { this.Board() }
      if (this.gameId === 'linktiles' || this.gameId === 'mahjongsolitaire') {
        Button($r('app.string.expansion_rearrange')).enabled(!this.vm.puzzleStuck).onClick(() => { this.vm.action(); })
      }
    }.width('100%')
  }
  @Builder
  Board() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.gameId === 'linktiles') {
        Stack() {}.width(this.unit() * 7).height(this.unit() * (this.vm.state.rows + 1))
          .border({ width: 1, color: SemanticColors.textSecondary, style: BorderStyle.Dashed }).borderRadius(RadiusTokens.sm)
          .translate({ x: this.unit() / 2, y: this.unit() / 2 }).hitTestBehavior(HitTestMode.None)
      }
      ForEach(range(this.vm.state.board.length), (index: number) => {
        Column() {
          if (this.gameId === 'linktiles') {
            Button(this.symbol(this.vm.state.board[index]), { type: ButtonType.Normal })
              .width('100%').height('100%').padding(0).fontSize(FontTokens.sizeTitle).fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.linktile_ink')).backgroundColor(this.linkTileFace(this.vm.state.board[index]))
              .borderRadius(RadiusTokens.sm).border({ width: this.vm.state.selected === index || this.vm.state.tray.includes(index) ? 3 : 1, color: this.vm.state.selected === index || this.vm.state.tray.includes(index) ? SemanticColors.primary : SemanticColors.border })
              .enabled(this.vm.state.board[index] > 0).id('linktile-' + index)
              .onClick(() => { this.vm.tap(index); })
          } else {
            GameArtTile({ image: this.vm.state.board[index] === 0 ? $r('app.media.exp_empty') : ExpansionArt.tile(this.vm.state.board[index] - 1),
          selected: this.vm.state.selected === index || this.vm.state.tray.includes(index),
          description: $r('app.string.expansion_cell', Math.floor(index / 6) + 1, index % 6 + 1, this.symbol(this.vm.state.board[index])),
          onTap: () => { this.vm.tap(index); } })
          }
        }.width(this.unit() - (this.gameId === 'linktiles' ? 3 : 4)).height(this.unit() - (this.gameId === 'linktiles' ? 3 : 4))
          .opacity(this.vm.state.board[index] === 0 ? 0.2 : 1)
          .translate({ x: (index % 6 + (this.gameId === 'linktiles' ? 1 : 0)) * this.unit() + 2,
            y: (Math.floor(index / 6) + (this.gameId === 'linktiles' ? 1 : 0)) * this.unit() + 2 })
          .accessibilityText($r('app.string.expansion_cell', Math.floor(index / 6) + 1, index % 6 + 1, this.symbol(this.vm.state.board[index])))
      }, (index: number) => index.toString())
      if (this.gameId === 'linktiles') {
        ForEach(range(Math.max(0, this.vm.state.data.length - 1)), (segment: number) => {
          Line().width('100%').height('100%').startPoint(this.pathPoint(this.vm.state.data[segment]))
            .endPoint(this.pathPoint(this.vm.state.data[segment + 1])).strokeWidth(3).stroke(SemanticColors.success).hitTestBehavior(HitTestMode.None)
        }, (segment: number) => segment.toString())
      }
    }.width('100%').aspectRatio((this.gameId === 'linktiles' ? 8 : 6) / (this.vm.state.rows + (this.gameId === 'linktiles' ? 2 : 0)))
      .backgroundColor(SemanticColors.boardBg).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base).onAreaChange((oldArea: Area, area: Area) => { this.measure(area); })
  }
  mahjongFace(value: number): Resource {
    const faces: Resource[] = [$r('app.string.mahjong_pair_face_1'), $r('app.string.mahjong_pair_face_2'), $r('app.string.mahjong_pair_face_3'),
      $r('app.string.mahjong_pair_face_4'), $r('app.string.mahjong_pair_face_5')];
    return faces[value - 1];
  }
  @Builder
  Mahjong() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.vm.worldPieces, (rendered: ExpansionRenderPiece) => {
        if (rendered.piece.alive) {
          Stack() {
            Text(this.mahjongFace(rendered.piece.color)).fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Bold)
              .fontColor(!this.vm.tileFree(rendered.id) ? $r('app.color.mahjong_locked_ink') :
                rendered.piece.color === 5 || rendered.piece.color === 1 ? SemanticColors.errorText : rendered.piece.color === 3 ? SemanticColors.successText : SemanticColors.textPrimary)
              .id('mahjong-face-' + rendered.id).accessibilityLevel('no').hitTestBehavior(HitTestMode.None)
            Button({ type: ButtonType.Normal }) {}.width('100%').height('100%').padding(0).backgroundColor(Color.Transparent)
              .enabled(this.vm.tileFree(rendered.id)).id('mahjong-pair-' + rendered.id)
              .accessibilityText($r('app.string.expansion_mahjong_tile', rendered.id + 1, resolveString(this.mahjongFace(rendered.piece.color), this.getUIContext().getHostContext()), rendered.piece.owner + 1))
              .onClick(() => { this.vm.tap(rendered.id); })
          }.width(this.unit() - 7).height(this.unit() - 7).id('mahjong-surface-' + rendered.id)
            .backgroundColor(this.vm.tileFree(rendered.id) ? $r('app.color.mahjong_pair_face') : $r('app.color.mahjong_locked_face')).borderRadius(RadiusTokens.xs)
            .border({ width: { left: 1, top: 1, right: 2, bottom: 4 }, color: this.vm.state.selected === rendered.id || this.vm.state.tray.includes(rendered.id) ? SemanticColors.primary : $r('app.color.mahjong_pair_edge') })
            .translate({ x: rendered.piece.x * this.unit() + 2 + rendered.piece.owner * 2, y: rendered.piece.y * this.unit() + 2 + rendered.piece.owner * 2 })
        }
      }, (rendered: ExpansionRenderPiece) => rendered.id.toString())
    }.width('100%').aspectRatio(6 / 4).backgroundColor(SemanticColors.boardBg).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
      .onAreaChange((oldArea: Area, area: Area) => { this.measure(area); })
  }
}
