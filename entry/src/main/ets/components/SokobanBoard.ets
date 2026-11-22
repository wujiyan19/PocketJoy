import { RadiusTokens, SpacingTokens } from '../common/DesignTokens';
import { Haptics } from '../common/Haptics';
import { resolveString } from '../common/I18nUtils';
import { range } from '../common/Range';
import { WarehouseTile, warehouseBoxAt } from '../model/game/ExpansionAdventure';
import { ExpansionPiece } from '../model/game/ExpansionState';
import { ExpansionViewModel } from '../viewmodel/ExpansionViewModel';

const DIRECTIONS: Resource[] = [$r('app.string.a11y_direction_up'), $r('app.string.a11y_direction_right'),
  $r('app.string.a11y_direction_down'), $r('app.string.a11y_direction_left')];

@ComponentV2
struct WarehouseCell {
  @Param @Require vm: ExpansionViewModel;
  @Param index: number = 0;

  @Computed get tile(): number { return this.vm.state.board[this.index]; }
  @Computed get player(): boolean { return this.vm.state.cursor === this.index; }
  @Computed get box(): ExpansionPiece | undefined { return warehouseBoxAt(this.vm.state, this.index); }
  @Computed get matching(): boolean {
    return this.box !== undefined && this.tile === (this.box.color === 1 ? WarehouseTile.StarGoal : WarehouseTile.Goal);
  }
  @Computed get groundColor(): Resource {
    if (this.tile === WarehouseTile.Wall) { return $r('app.color.sokoban_wall_edge'); }
    if (this.tile === WarehouseTile.StarGoal) { return $r('app.color.sokoban_star_pad'); }
    if (this.tile === WarehouseTile.Goal) { return $r('app.color.sokoban_goal_pad'); }
    return $r('app.color.sokoban_floor');
  }
  description(): Resource {
    const host = this.getUIContext().getHostContext();
    let ground: Resource = $r('app.string.sokoban_cell_floor');
    if (this.tile === WarehouseTile.Wall) { ground = $r('app.string.sokoban_cell_wall'); }
    else if (this.tile === WarehouseTile.Goal) { ground = $r('app.string.sokoban_cell_goal'); }
    else if (this.tile === WarehouseTile.StarGoal) { ground = $r('app.string.sokoban_cell_star_goal'); }
    else if (this.tile >= WarehouseTile.Up) {
      ground = $r('app.string.sokoban_cell_arrow', resolveString(DIRECTIONS[this.tile - WarehouseTile.Up], host));
    }
    let label: string = resolveString(ground, host);
    if (this.player || this.box !== undefined) {
      const occupant: Resource = this.player ? $r('app.string.sokoban_cell_player') :
        this.box?.color === 1 ? $r('app.string.sokoban_cell_star_box') : $r('app.string.sokoban_cell_box');
      label = resolveString(occupant, host) + ' · ' + label;
    }
    return $r('app.string.expansion_cell', Math.floor(this.index / this.vm.state.cols) + 1,
      this.index % this.vm.state.cols + 1, label);
  }

  @Builder
  Mark(size: Length) {
    Image(this.matching ? $r('app.media.sokoban_done_mark') :
      this.tile === WarehouseTile.Goal ? $r('app.media.sokoban_ring_mark') :
      this.tile === WarehouseTile.StarGoal ? $r('app.media.sokoban_star_mark') : $r('app.media.sokoban_arrow_mark'))
      .width(size).height(size).objectFit(ImageFit.Contain)
      .fillColor(this.tile === WarehouseTile.Goal ? $r('app.color.sokoban_goal_ink') :
        this.tile === WarehouseTile.StarGoal ? $r('app.color.sokoban_star_ink') : $r('app.color.sokoban_arrow_ink'))
      .rotate({ angle: this.tile >= WarehouseTile.Up ? (this.tile - WarehouseTile.Up) * 90 : 0 })
      .accessibilityLevel('no')
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.tile === WarehouseTile.Wall) {
        Image($r('app.media.sokoban_masonry')).width('100%').height('100%').objectFit(ImageFit.Fill).accessibilityLevel('no')
        if (this.index + this.vm.state.cols < this.vm.state.board.length &&
          this.vm.state.board[this.index + this.vm.state.cols] !== WarehouseTile.Wall) {
          Rect().width('100%').height('12%').fill($r('app.color.sokoban_wall_edge')).accessibilityLevel('no')
        }
      } else {
        Stack() {
          if (this.player || this.box !== undefined) {
            Image(this.player ? $r('app.media.exp_robot') :
              this.box?.color === 1 ? $r('app.media.sokoban_star_crate') : $r('app.media.exp_crate'))
              .width(this.player ? '100%' : '88%').height(this.player ? '100%' : '88%')
              .objectFit(ImageFit.Contain).accessibilityLevel('no')
          } else if (this.tile >= WarehouseTile.Goal) {
            this.Mark(this.tile >= WarehouseTile.Up ? '48%' : '70%')
          }
        }.width('100%').height('100%').accessibilityLevel('no')
        if ((this.player || this.box !== undefined) && this.tile >= WarehouseTile.Goal) {
          Stack() {
            this.Mark('82%')
          }.width('32%').aspectRatio(1).backgroundColor(this.groundColor).borderRadius(RadiusTokens.xs).accessibilityLevel('no')
        }
      }
    }.width('100%').height('100%').backgroundColor(this.groundColor)
      .border({ width: { top: this.tile === WarehouseTile.Wall ? 0 : 0.5, left: this.tile === WarehouseTile.Wall ? 0 : 0.5 },
        color: $r('app.color.sokoban_grout') })
      .id('sokoban-cell-' + this.index)
      .accessibilityGroup(true).accessibilityLevel('yes').accessibilityText(this.description())
  }
}

@ComponentV2
export struct SokobanBoard {
  @Param @Require vm: ExpansionViewModel;
  @Param boardWidth: Length = '100%';

  build() {
    Column() {
      ForEach(range(this.vm.state.rows), (row: number) => {
        Row() {
          ForEach(range(this.vm.state.cols), (col: number) => {
            WarehouseCell({ vm: this.vm, index: row * this.vm.state.cols + col }).layoutWeight(1).height('100%')
          }, (col: number) => col.toString())
        }.width('100%').layoutWeight(1)
      }, (row: number) => row.toString())
    }.id('sokoban-board').width(this.boardWidth).aspectRatio(1).backgroundColor($r('app.color.sokoban_wall_edge'))
      .borderRadius(RadiusTokens.md).clip(true)
      .priorityGesture(PanGesture({ fingers: 1, direction: PanDirection.All, distance: SpacingTokens.base })
        .onActionStart(() => { this.vm.setDragging(true); })
        .onActionEnd((event: GestureEvent) => {
          this.vm.setDragging(false);
          if (Math.max(Math.abs(event.offsetX), Math.abs(event.offsetY)) < SpacingTokens.base) { return; }
          const direction: number = Math.abs(event.offsetX) > Math.abs(event.offsetY) ?
            (event.offsetX > 0 ? 1 : 3) : (event.offsetY > 0 ? 2 : 0);
          const previousMoves: number = this.vm.state.moves;
          this.vm.tap(direction);
          if (this.vm.state.moves > previousMoves) { Haptics.tap(); }
        })
        .onActionCancel(() => { this.vm.setDragging(false); }))
  }
}
