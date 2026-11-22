import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ExpansionRenderPiece } from '../../viewmodel/ExpansionRenderPiece';
import { ExpansionPiece } from '../../model/game/ExpansionState';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { range } from '../../common/Range';
import { ExpansionArt } from '../../common/ExpansionArt';
import { Haptics } from '../../common/Haptics';
import { HarmonyMotion } from '../../common/HarmonyMotion';
import { resolveString } from '../../common/I18nUtils';
import { ToyRollingStage } from '../../components/ToyRollingStage';
import { ToyDriftStage } from '../../components/ToyDriftStage';
import { grappleAnchor } from '../../model/game/ExpansionAction';

const WORLD_INPUT_IDS: string[] = ['platformer', 'grapple', 'flappy', 'fruitslice', 'shooter', 'tanks', 'fortress', 'survival', 'pingpong', 'airhockey'];
const WORLD_TOUCH_ARENAS: string[] = ['flappy', 'fruitslice', 'shooter', 'tanks', 'fortress', 'survival', 'pingpong', 'airhockey'];

@ComponentV2
export struct ExpansionWorldBoard {
  @Param gameId: string = '';
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Param heightLimit: number = 460;
  @Local arenaWidth: number = 320;
  private jumpFromTouch: boolean = false;
  private hookPressedAt: number = 0;
  @Local bladePath: number[][] = [];
  @Local ballTrail: number[][] = [];
  @Monitor('vm.state')
  updateBallTrail(): void {
    if (this.gameId !== 'pingpong' && this.gameId !== 'airhockey') { return; }
    const ball: ExpansionPiece = this.vm.state.pieces[0];
    if (!ball || this.vm.state.phase === 0) { this.ballTrail = []; return; }
    const previous: number[] | undefined = this.ballTrail[this.ballTrail.length - 1];
    const tail: number[][] = previous && Math.hypot(previous[0] - ball.x, previous[1] - ball.y) < 45 ? this.ballTrail.slice(-3) : [];
    this.ballTrail = [...tail, [ball.x, ball.y]];
  }
  private bladeTimer: number = -1;
  private planeOffsetX: number = 0;
  private planeOffsetY: number = 0;
  @Local fortressAngle: number = -Math.PI / 2;
  aboutToDisappear(): void { if (this.bladeTimer >= 0) { clearTimeout(this.bladeTimer); } }
  @Computed get hookTarget(): number {
    return this.vm.state.selected >= 0 ? this.vm.state.selected : grappleAnchor(this.vm.state)?.id ?? -1;
  }
  arenaScale(): number { return this.arenaWidth / 360; }
  camera(): number { return ['platformer', 'grapple', 'hillclimb'].includes(this.gameId) ? Math.max(0, this.vm.state.pieces[0].x - 160) : 0; }
  measure(area: Area): void { const width: number = Number(area.width); if (Number.isFinite(width) && width > 0) { this.arenaWidth = width; } }
  glyph(p: ExpansionPiece): string {
    if (p.kind === 24) { return ['shooter', 'tanks', 'fortress'].includes(this.gameId) ? (this.gameId === 'shooter' ? '✈' : '▣') : '●'; }
    if (p.kind === 27) { return '⚑'; } if (p.kind === 28) { return '⊙'; } if (p.kind === 30) { return ['🍒', '🍊', '🍎', '🍐', '🍑', '🍓'][(p.color - 1) % 6]; }
    if (p.kind === 31) { return this.gameId === 'fruitslice' ? '💣' : '●'; } if (p.kind === 33) { return this.gameId === 'tanks' ? '▣' : '👾'; }
    if (p.kind === 36) { return '🚙'; } if (p.kind === 37) { return '♟'; } if (p.kind === 43) { return '⚑'; } if (p.kind === 44) { return '🧤'; }
    return '';
  }
  pieceColor(p: ExpansionPiece): Resource {
    if (p.kind === 42 || p.kind === 31) { return SemanticColors.textPrimary; }
    if (p.kind === 25 || p.kind === 26 || p.kind === 37) { return SemanticColors.border; }
    if (p.kind === 33 || p.owner === 1) { return SemanticColors.error; }
    if (p.kind === 27 || p.kind === 43) { return SemanticColors.success; }
    const colors: Resource[] = [$r('app.color.expansion_color_1'), $r('app.color.expansion_color_2'), $r('app.color.expansion_color_3'),
      $r('app.color.expansion_color_4'), $r('app.color.expansion_color_5'), $r('app.color.expansion_color_6')];
    return p.color > 0 ? colors[(p.color - 1) % 6] : SemanticColors.primary;
  }
  pieceWidth(p: ExpansionPiece): number { return p.kind === 25 || p.kind === 26 || (p.kind === 39 && p.r === 0) ? p.w : p.r * 2; }
  pieceHeight(p: ExpansionPiece): number { return p.kind === 25 || p.kind === 26 || (p.kind === 39 && p.r === 0) ? p.h : p.r * 2; }
  pieceX(p: ExpansionPiece): number { return (p.kind === 25 || p.kind === 26 ? p.x : p.x - this.pieceWidth(p) / 2) - this.camera(); }
  tankHeading(p: ExpansionPiece): number {
    const target: ExpansionPiece | undefined = p.kind === 33 ? this.vm.state.pieces[0] :
      this.vm.state.pieces.filter((q: ExpansionPiece) => q.kind === 33 && q.alive)
        .sort((a: ExpansionPiece, b: ExpansionPiece) => Math.hypot(a.x - p.x, a.y - p.y) - Math.hypot(b.x - p.x, b.y - p.y))[0];
    return target ? Math.atan2(target.y - p.y, target.x - p.x) * 180 / Math.PI + 90 : 0;
  }
  pieceY(p: ExpansionPiece): number { return p.kind === 25 || p.kind === 26 ? p.y : p.y - this.pieceHeight(p) / 2; }
  @Computed get hillGround(): number[][] {
    if (this.vm.state.id !== 'hillclimb') { return []; }
    const offset: number = this.camera();
    const scale: number = this.arenaScale();
    return range(31).map((i: number): number[] => [i * 12 * scale, this.vm.terrain(offset + i * 12) * scale]);
  }
  hillAngle(x: number): number { return Math.atan2(this.vm.terrain(x + 8) - this.vm.terrain(x - 8), 16) * 180 / Math.PI; }
  roadPoint(i: number, side: number): number[] { const y: number = i * 46; const center: number = 180 + Math.sin((this.vm.state.time + (390 - y) / 100) * 0.65) * 90; return [(center + side * 65) * this.arenaScale(), y * this.arenaScale()]; }
  touch(event: TouchEvent): void {
    if (this.gameId === 'fruitslice' && this.vm.state.phase !== 0) {
      if (event.type === TouchType.Down) {
        if (this.bladeTimer >= 0) { clearTimeout(this.bladeTimer); this.bladeTimer = -1; }
        this.bladePath = [[event.touches[0].x, event.touches[0].y]];
      } else if (event.type === TouchType.Move && this.vm.dragging && event.touches.length > 0) {
        this.bladePath = this.bladePath.slice(-5);
        this.bladePath = [...this.bladePath, [event.touches[0].x, event.touches[0].y]];
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.bladeTimer = setTimeout(() => { this.bladePath = []; this.bladeTimer = -1; }, 150);
      }
    }
    if (this.gameId === 'flappy') {
      if (event.type === TouchType.Down && this.vm.state.phase !== 0) { this.vm.tap(0); }
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.vm.setDragging(false); return; }
    if (event.touches.length === 0) { return; }
    if (event.type === TouchType.Down) { this.vm.setDragging(true); }
    if (this.gameId === 'fortress' && this.vm.state.phase !== 0) {
      if (event.type === TouchType.Down || (event.type === TouchType.Move && this.vm.dragging)) {
        const serial: number = this.vm.state.serial;
        this.vm.aim(event.touches[0].x / this.arenaScale(), event.touches[0].y / this.arenaScale());
        if (this.vm.state.serial !== serial) {
          const shot: ExpansionPiece = this.vm.state.pieces[this.vm.state.pieces.length - 1];
          this.fortressAngle = Math.atan2(shot.vy, shot.vx);
        }
      }
      return;
    }
    if (this.gameId === 'shooter') {
      const x: number = event.touches[0].x / this.arenaScale(); const y: number = event.touches[0].y / this.arenaScale();
      if (event.type === TouchType.Down) {
        this.planeOffsetX = this.vm.state.pieces[0].x - x; this.planeOffsetY = this.vm.state.pieces[0].y - y;
      } else if (event.type === TouchType.Move && this.vm.dragging) {
        this.vm.aim(x + this.planeOffsetX, y + this.planeOffsetY);
      }
      return;
    }
    if (event.type === TouchType.Down || (event.type === TouchType.Move && this.vm.dragging && ['fruitslice', 'rollingball', 'shooter', 'tanks', 'survival', 'pingpong', 'airhockey'].includes(this.gameId))) {
      this.vm.aim(event.touches[0].x / this.arenaScale(), event.touches[0].y / this.arenaScale());
    }
  }
  hold(event: TouchEvent, command: number, release: number): void {
    if (event.type === TouchType.Down) { this.vm.setDragging(true); this.vm.tap(command); }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.vm.tap(release); this.vm.setDragging(false); }
  }
  build() {
    Column({ space: SpacingTokens.base }) {
      if (this.gameId === 'backpack') { this.Backpack() } else if (this.gameId === 'dots') { this.Dots() }
      else if (this.gameId === 'tug') { this.Tug() } else {
        if (this.gameId === 'rollingball') {
          Text($r('app.string.rolling_touch_guide')).fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textSecondary)
          ToyRollingStage({ vm: this.vm })
        }
        else if (this.gameId === 'drift') { ToyDriftStage({ vm: this.vm, heightLimit: this.heightLimit }) }
        else { this.Arena() }
        if (this.vm.state.phase === 0 && !['billiards', 'golf', 'bowling', 'survival'].includes(this.gameId)) {
          if (this.gameId === 'drift') {
            Button($r('app.string.expansion_ready')).width('100%').height($r('app.float.expansion_control_height'))
              .onClick(() => { this.vm.activate(); })
          } else {
            Button($r('app.string.expansion_ready')).onClick(() => { this.vm.activate(); })
          }
        }
        if (this.gameId === 'platformer') {
          Row({ space: SpacingTokens.sm }) {
            Button('←').layoutWeight(1).height($r('app.float.expansion_control_height')).id('platformer-left').accessibilityText($r('app.string.expansion_left'))
              .onTouch((event: TouchEvent) => { this.hold(event, 0, 3); })
            Button('→').layoutWeight(1).height($r('app.float.expansion_control_height')).id('platformer-right').accessibilityText($r('app.string.expansion_right'))
              .onTouch((event: TouchEvent) => { this.hold(event, 1, 3); })
            Blank().layoutWeight(0.35)
            Button($r('app.string.expansion_jump')).layoutWeight(1.6).height($r('app.float.expansion_control_height')).id('platformer-jump')
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) { this.jumpFromTouch = true; this.vm.tap(2); }
                if (event.type === TouchType.Cancel) { this.jumpFromTouch = false; }
              }).onClick(() => { if (!this.jumpFromTouch) { this.vm.tap(2); } this.jumpFromTouch = false; })
          }.width('100%')
        }
        if (this.gameId === 'grapple') {
          Row({ space: SpacingTokens.sm }) {
            Button(this.vm.state.selected >= 0 ? $r('app.string.grapple_attached') : $r('app.string.expansion_hook'))
              .layoutWeight(1).height($r('app.float.expansion_control_height')).id('grapple-hook')
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) { this.hookPressedAt = Date.now(); this.vm.tap(0); }
                if (event.type === TouchType.Up && this.vm.state.selected >= 0 && Date.now() - this.hookPressedAt >= 300) { this.vm.tap(1); }
                if (event.type === TouchType.Cancel) { this.hookPressedAt = 0; }
              }).onClick(() => { if (this.hookPressedAt === 0) { this.vm.tap(0); } this.hookPressedAt = 0; })
            Button($r('app.string.expansion_release')).layoutWeight(1).height($r('app.float.expansion_control_height')).id('grapple-release')
              .enabled(this.vm.state.selected >= 0).onClick(() => { this.vm.tap(1); })
          }.width('100%')
        }
        if (this.gameId === 'flappy') { Button($r('app.string.expansion_flap')).id('flappy-flap').height($r('app.float.expansion_control_height')).width('100%').onClick(() => { this.vm.tap(0); }) }
        if (this.gameId === 'tanks') {
          Text($r('app.string.tanks_steer_hint')).fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textSecondary)
        }
        if (this.gameId === 'pingpong') {
          Text($r('app.string.pingpong_control_band')).width('100%').height($r('app.float.expansion_control_height'))
            .textAlign(TextAlign.Center).fontColor(SemanticColors.primary).backgroundColor(SemanticColors.selectionSurface)
            .borderRadius(RadiusTokens.md).id('pingpong-band').onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.vm.setDragging(false); return; }
              if (event.touches.length > 0) { this.vm.setDragging(true); this.vm.aim(event.touches[0].x / this.arenaScale(), 420); }
            })
        }
        if (this.gameId === 'fortress') {
          Button(this.vm.state.next >= 5 ? $r('app.string.fortress_max') : $r('app.string.expansion_upgrade'))
            .enabled(this.vm.state.data[1] >= 20 && this.vm.state.next < 5).id('fortress-upgrade').onClick(() => { this.vm.tap(0); })
        }
        if (this.gameId === 'survival' && this.vm.state.variant === 1) {
          Text($r('app.string.survival_points_cost', this.vm.state.data[1])).fontSize(FontTokens.sizeBodySmall)
            .fontColor(SemanticColors.textSecondary).id('survival-points')
          Row({ space: SpacingTokens.xs }) {
            Button($r('app.string.survival_power_tier', this.vm.state.board[0])).layoutWeight(1).height($r('app.float.home_action_min_height'))
              .padding(SpacingTokens.xs).id('survival-power').enabled(this.vm.state.data[1] >= 20 && this.vm.state.board[0] < 3).onClick(() => { this.vm.tap(0); })
            Button($r('app.string.survival_rate_tier', this.vm.state.board[1])).layoutWeight(1).height($r('app.float.home_action_min_height'))
              .padding(SpacingTokens.xs).id('survival-rate').enabled(this.vm.state.data[1] >= 20 && this.vm.state.board[1] < 3).onClick(() => { this.vm.tap(1); })
            Button($r('app.string.survival_restore_one')).layoutWeight(1).height($r('app.float.home_action_min_height')).padding(SpacingTokens.xs)
              .id('survival-heal').enabled(this.vm.state.data[1] >= 20 && this.vm.state.data[0] < 3).onClick(() => { this.vm.tap(2); })
          }.width('100%')
        }
        if (this.gameId === 'drift' && this.vm.state.phase !== 0) { Button($r('app.string.expansion_drift')).width('100%').height($r('app.float.expansion_control_height')).onClick(() => { this.vm.tap(0); }) }
        if (this.gameId === 'hillclimb') {
          Text($r('app.string.hill_reading', Math.round(this.vm.state.pieces[0].vx), Math.round(-this.hillAngle(this.vm.state.pieces[0].x))))
            .id('hill-reading').fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textSecondary)
          Row({ space: SpacingTokens.sm }) {
            Button($r('app.string.expansion_brake')).layoutWeight(1).height($r('app.float.expansion_control_height')).id('hill-brake').onTouch((event: TouchEvent) => { this.hold(event, 1, 2); })
            Button($r('app.string.expansion_gas')).layoutWeight(1).height($r('app.float.expansion_control_height')).id('hill-gas').onTouch((event: TouchEvent) => { this.hold(event, 0, 2); })
          }.width('100%')
        }
      }
    }.width('100%')
  }
  @Builder
  Arena() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.gameId === 'airhockey') {
        Image(ExpansionArt.board(this.gameId)).width('100%').height('100%').objectFit(ImageFit.Fill).hitTestBehavior(HitTestMode.None)
      }
      if (this.gameId === 'shooter') {
        ForEach([-1, 0], (copy: number) => {
          Image(ExpansionArt.board(this.gameId)).width('100%').height('100%').objectFit(ImageFit.Fill)
            .translate({ y: (copy * 460 + (this.vm.state.time * 25) % 460) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
        }, (copy: number) => copy.toString())
      }
      if (this.gameId === 'fruitslice') {
        Image(ExpansionArt.board(this.gameId)).width('100%').height('100%').objectFit(ImageFit.Fill).hitTestBehavior(HitTestMode.None)
        if (this.vm.state.phase === 0) {
          Text($r('app.string.fruitslice_swipe_hint')).width('100%').textAlign(TextAlign.Center).fontColor(Color.White)
            .fontSize(FontTokens.sizeBody).translate({ y: 180 * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
        }
      }
      if (this.gameId === 'flappy') {
        Row() {
          ForEach(range(18), (i: number) => {
            Column().layoutWeight(1).height('100%').backgroundColor(i % 2 === 0 ? SemanticColors.warning : SemanticColors.warningText)
          }, (i: number) => i.toString())
        }.width('100%').height(6 * this.arenaScale()).translate({ y: 454 * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
      }
      if (this.gameId === 'fortress') {
        Column() {
          Text($r('app.string.fortress_wall_health', this.vm.state.data[0])).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textPrimary)
          Progress({ value: this.vm.state.data[0], total: 100, type: ProgressType.Linear }).width('90%').color(SemanticColors.successText)
        }.width('100%').height(33 * this.arenaScale()).backgroundColor(SemanticColors.surface)
          .translate({ y: 427 * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
        ForEach([0, 1, 2], (i: number) => {
          Line().width('100%').height('100%').strokeWidth(2).stroke(SemanticColors.primary)
            .startPoint([(this.vm.state.pieces[0].x + Math.cos(this.fortressAngle) * (24 + 12 * i)) * this.arenaScale(),
              (this.vm.state.pieces[0].y + Math.sin(this.fortressAngle) * (24 + 12 * i)) * this.arenaScale()])
            .endPoint([(this.vm.state.pieces[0].x + Math.cos(this.fortressAngle) * (31 + 12 * i)) * this.arenaScale(),
              (this.vm.state.pieces[0].y + Math.sin(this.fortressAngle) * (31 + 12 * i)) * this.arenaScale()])
            .hitTestBehavior(HitTestMode.None)
        }, (i: number) => i.toString())
      }
      if (this.gameId === 'pingpong' || this.gameId === 'airhockey') { Line().width('100%').height('100%').startPoint([0, 230 * this.arenaScale()]).endPoint([this.arenaWidth, 230 * this.arenaScale()])
        .strokeWidth(this.gameId === 'pingpong' ? 3 : 2).stroke(this.gameId === 'pingpong' ? SemanticColors.textSecondary : SemanticColors.border).hitTestBehavior(HitTestMode.None) }
      if ((this.gameId === 'pingpong' || this.gameId === 'airhockey') && this.ballTrail.length > 1) {
        ForEach(range(this.ballTrail.length - 1), (i: number) => {
          Line().width('100%').height('100%').startPoint([this.ballTrail[i][0] * this.arenaScale(), this.ballTrail[i][1] * this.arenaScale()])
            .endPoint([this.ballTrail[i + 1][0] * this.arenaScale(), this.ballTrail[i + 1][1] * this.arenaScale()])
            .strokeWidth(3).stroke(SemanticColors.primary).opacity((i + 1) * 0.18).hitTestBehavior(HitTestMode.None)
        }, (i: number) => i.toString())
      }
      if (this.gameId === 'penalty') { Line().width('100%').height('100%').startPoint([30 * this.arenaScale(), 95 * this.arenaScale()]).endPoint([330 * this.arenaScale(), 95 * this.arenaScale()]).strokeWidth(4).stroke(SemanticColors.success).hitTestBehavior(HitTestMode.None) }
      if (this.gameId === 'hillclimb') {
        Image(ExpansionArt.board(this.gameId)).width('100%').height('100%').objectFit(ImageFit.Fill).hitTestBehavior(HitTestMode.None)
        Polygon().width('100%').height('100%')
          .points([...this.hillGround, [this.arenaWidth, 460 * this.arenaScale()], [0, 460 * this.arenaScale()]])
          .fill($r('app.color.hill_soil')).hitTestBehavior(HitTestMode.None)
        Polyline().width('100%').height('100%').points(this.hillGround).fill(Color.Transparent)
          .strokeWidth(4).stroke(SemanticColors.success).hitTestBehavior(HitTestMode.None)
      }
      if (this.gameId === 'drift') {
        ForEach(range(10), (i: number) => {
          Line().width('100%').height('100%').startPoint(this.roadPoint(i, -1)).endPoint(this.roadPoint(i + 1, -1)).strokeWidth(4).stroke($r('app.color.expansion_road_edge')).hitTestBehavior(HitTestMode.None)
          Line().width('100%').height('100%').startPoint(this.roadPoint(i, 1)).endPoint(this.roadPoint(i + 1, 1)).strokeWidth(4).stroke($r('app.color.expansion_road_edge')).hitTestBehavior(HitTestMode.None)
        }, (i: number) => i.toString())
      }
      ForEach(this.vm.worldPieces, (rendered: ExpansionRenderPiece) => {
        if (rendered.piece.kind === 29) {
          Image($r('app.media.exp_gate')).objectFit(ImageFit.Fill).width(rendered.piece.w * this.arenaScale()).height((rendered.piece.y - rendered.piece.h / 2) * this.arenaScale()).scale({ y: -1 })
            .translate({ x: (rendered.piece.x - rendered.piece.w / 2) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
          Image($r('app.media.exp_gate')).objectFit(ImageFit.Fill).width(rendered.piece.w * this.arenaScale()).height((460 - rendered.piece.y - rendered.piece.h / 2) * this.arenaScale())
            .translate({ x: (rendered.piece.x - rendered.piece.w / 2) * this.arenaScale(), y: (rendered.piece.y + rendered.piece.h / 2) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
          if (this.gameId === 'flappy') {
            ForEach([-1, 1], (edge: number) => {
              Column().width(rendered.piece.w * this.arenaScale()).height(7 * this.arenaScale())
                .backgroundColor(SemanticColors.successText).translate({
                x: (rendered.piece.x - rendered.piece.w / 2) * this.arenaScale(),
                y: (rendered.piece.y + edge * rendered.piece.h / 2 - (edge < 0 ? 7 : 0)) * this.arenaScale()
              }).hitTestBehavior(HitTestMode.None)
            }, (edge: number) => edge.toString())
          }
        } else if (this.gameId === 'hillclimb' && rendered.piece.kind === 36) {
          Image($r('app.media.exp_hill_truck')).width(52 * this.arenaScale()).height(32 * this.arenaScale()).objectFit(ImageFit.Fill)
            .rotate({ angle: this.hillAngle(rendered.piece.x) }).id('hill-truck')
            .translate({ x: (rendered.piece.x - this.camera() - 26) * this.arenaScale(), y: (rendered.piece.y - 16) * this.arenaScale() })
            .hitTestBehavior(HitTestMode.None)
        } else if (this.gameId === 'pingpong' && rendered.piece.kind === 39) {
          Column().width(rendered.piece.w * this.arenaScale()).height(rendered.piece.h * this.arenaScale())
            .borderRadius(rendered.piece.owner === 1 ? RadiusTokens.xs : RadiusTokens.full)
            .backgroundColor(rendered.piece.owner === 1 ? SemanticColors.errorText : SemanticColors.primary)
            .border({ width: 1, color: Color.White }).translate({ x: this.pieceX(rendered.piece) * this.arenaScale(), y: this.pieceY(rendered.piece) * this.arenaScale() })
            .id(rendered.piece.owner === 1 ? 'pingpong-paddle-1' : 'pingpong-paddle-0').hitTestBehavior(HitTestMode.None)
        } else if (this.gameId === 'survival' && rendered.piece.kind === 34) {
          Line().width('100%').height('100%')
            .startPoint([(rendered.piece.x - rendered.piece.vx * 0.065) * this.arenaScale(), (rendered.piece.y - rendered.piece.vy * 0.065) * this.arenaScale()])
            .endPoint([rendered.piece.x * this.arenaScale(), rendered.piece.y * this.arenaScale()])
            .strokeWidth(5 * this.arenaScale()).stroke($r('app.color.survival_shot_rim')).hitTestBehavior(HitTestMode.None)
          Line().width('100%').height('100%')
            .startPoint([(rendered.piece.x - rendered.piece.vx * 0.065) * this.arenaScale(), (rendered.piece.y - rendered.piece.vy * 0.065) * this.arenaScale()])
            .endPoint([rendered.piece.x * this.arenaScale(), rendered.piece.y * this.arenaScale()])
            .strokeWidth(3 * this.arenaScale()).stroke($r('app.color.survival_shot_trail')).hitTestBehavior(HitTestMode.None)
          Column().width(rendered.piece.r * 2 * this.arenaScale()).height(rendered.piece.r * 2 * this.arenaScale())
            .backgroundColor($r('app.color.survival_shot_core')).border({ width: 1, color: $r('app.color.survival_shot_rim') }).borderRadius(RadiusTokens.full)
            .translate({ x: (rendered.piece.x - rendered.piece.r) * this.arenaScale(), y: (rendered.piece.y - rendered.piece.r) * this.arenaScale() })
            .id('survival-piece-34-' + rendered.id).hitTestBehavior(HitTestMode.None)
        } else if (this.gameId === 'tanks' && rendered.piece.kind === 34) {
          Column().width((rendered.piece.owner === 0 ? 10 : 13) * this.arenaScale()).height((rendered.piece.owner === 0 ? 14 : 13) * this.arenaScale())
            .borderRadius(rendered.piece.owner === 0 ? RadiusTokens.sm : RadiusTokens.full)
            .backgroundColor(rendered.piece.owner === 0 ? SemanticColors.successText : SemanticColors.errorText).border({ width: 1, color: Color.White })
            .translate({ x: (rendered.piece.x - 6) * this.arenaScale(), y: (rendered.piece.y - 7) * this.arenaScale() })
            .id('tank-shot-' + rendered.piece.owner + '-' + rendered.id).hitTestBehavior(HitTestMode.None)
        } else if (this.gameId === 'shooter' && rendered.piece.kind === 34) {
          Column().width(6 * this.arenaScale()).height(20 * this.arenaScale()).borderRadius(RadiusTokens.full)
            .backgroundColor(rendered.piece.owner === 0 ? $r('app.color.expansion_color_3') : $r('app.color.expansion_color_1'))
            .border({ width: 1, color: Color.White }).translate({ x: (rendered.piece.x - 3) * this.arenaScale(), y: (rendered.piece.y - 10) * this.arenaScale() })
            .id('shooter-shot-' + rendered.piece.owner + '-' + rendered.id).hitTestBehavior(HitTestMode.None)
        } else if (this.gameId === 'grapple' && rendered.piece.kind === 28) {
          Stack() {
            Column().width('100%').height('100%').borderRadius(RadiusTokens.full)
              .border({ color: rendered.id === this.hookTarget ? SemanticColors.primary : SemanticColors.border,
                width: rendered.id === this.hookTarget ? 3 : 1 })
            Image(ExpansionArt.piece(this.gameId, rendered.piece)).width('66%').height('66%').objectFit(ImageFit.Contain)
          }.width(30 * this.arenaScale()).height(30 * this.arenaScale())
            .translate({ x: (rendered.piece.x - this.camera() - 15) * this.arenaScale(), y: (rendered.piece.y - 15) * this.arenaScale() })
            .id('grapple-anchor-' + rendered.id).hitTestBehavior(HitTestMode.None)
        } else {
          Image(this.gameId === 'airhockey' && rendered.piece.kind === 39 && rendered.piece.owner === 1 ? $r('app.media.exp_air_opponent') :
            this.gameId === 'tanks' && rendered.piece.kind === 26 ? $r('app.media.exp_tanks_cover') :
            this.gameId === 'tanks' && rendered.piece.kind === 33 ? $r('app.media.exp_tanks_enemy') :
              this.gameId === 'shooter' && rendered.piece.kind === 33 ? $r('app.media.exp_shooter_foe') : ExpansionArt.piece(this.gameId, rendered.piece))
            .id(WORLD_INPUT_IDS.includes(this.gameId) ? this.gameId + '-piece-' + rendered.piece.kind + '-' + rendered.id : '')
            .width(this.pieceWidth(rendered.piece) * this.arenaScale()).height(this.pieceHeight(rendered.piece) * this.arenaScale())
            .objectFit(rendered.piece.kind === 25 || rendered.piece.kind === 26 || rendered.piece.kind === 39 ? ImageFit.Fill : ImageFit.Contain)
            .rotate({ angle: this.gameId === 'tanks' && (rendered.piece.kind === 24 || rendered.piece.kind === 33) ? this.tankHeading(rendered.piece) : 0 })
            .translate({ x: this.pieceX(rendered.piece) * this.arenaScale(), y: this.pieceY(rendered.piece) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
        }
      }, (rendered: ExpansionRenderPiece) => rendered.id.toString())
      if (this.gameId === 'grapple' && this.vm.state.selected >= 0) {
        ForEach(this.vm.worldPieces.filter((rendered: ExpansionRenderPiece) => rendered.id === this.vm.state.selected), (anchor: ExpansionRenderPiece) => {
          Line().width('100%').height('100%').startPoint([(anchor.piece.x - this.camera()) * this.arenaScale(), anchor.piece.y * this.arenaScale()])
            .endPoint([(this.vm.state.pieces[0].x - this.camera()) * this.arenaScale(), this.vm.state.pieces[0].y * this.arenaScale()])
            .strokeWidth(3).stroke(SemanticColors.primary).id('grapple-rope-' + anchor.id).hitTestBehavior(HitTestMode.None)
        }, (anchor: ExpansionRenderPiece) => anchor.id.toString())
      }
      if (this.gameId === 'survival' && this.vm.state.phase === 0) {
        Row() { Button($r('app.string.expansion_ready')).id('survival-start').onClick(() => { this.vm.activate(); }) }
          .width('100%').justifyContent(FlexAlign.Center).translate({ y: 195 * this.arenaScale() })
      }
      if (this.gameId === 'fruitslice' && this.bladePath.length > 1) {
        ForEach(range(this.bladePath.length - 1), (i: number) => {
          Line().width('100%').height('100%').startPoint(this.bladePath[i]).endPoint(this.bladePath[i + 1])
            .strokeWidth(3).stroke(Color.White).hitTestBehavior(HitTestMode.None)
        }, (i: number) => i.toString())
      }
    }.id(WORLD_TOUCH_ARENAS.includes(this.gameId) ? this.gameId + '-arena' : '').width('100%').aspectRatio(360 / 460).clip(true).backgroundColor(SemanticColors.boardBg).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
      .onAreaChange((oldArea: Area, area: Area) => { this.measure(area); }).onTouch((event: TouchEvent) => { this.touch(event); })
  }
  @Builder
  Backpack() {
    Column({ space: SpacingTokens.base }) {
      Text($r('app.string.expansion_pack_stats', this.vm.state.data[0], this.vm.state.data[1], this.vm.state.cursor, this.vm.state.goal))
        .fontFamily(FontTokens.family).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textPrimary)

      Grid() {
        // 直接使用当前棋盘快照；占格值改变时重建对应格子，撤销也立即刷新。
        ForEach(this.vm.state.board, (value: number, index: number) => {
          GridItem() {
            Button({ type: ButtonType.Normal }) {
              Stack() {
                Image($r('app.media.exp_pack_slot')).width('100%').height('100%').objectFit(ImageFit.Contain)
                  .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
                if (value > 0) {
                  Image(ExpansionArt.equipment(value - 1)).width('76%').height('76%').objectFit(ImageFit.Contain)
                    .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
                }
              }.width('100%').height('100%').renderGroup(true)
            }.width('100%').height('100%').padding(0).backgroundColor(Color.Transparent)
              .borderRadius(RadiusTokens.md).enabled(this.vm.state.outcome === 0)
              .clickEffect(HarmonyMotion.press(this.getUIContext()))
              .accessibilityText(this.packCellDescription(index, value))
              .onClick(() => { Haptics.tap(); this.vm.tap(index); })
          }.width('100%').height('100%')
        }, (value: number, index: number) => index.toString() + ':' + value.toString())
      }.width('100%').constraintSize({ maxWidth: $r('app.float.art_backpack_board_max') }).aspectRatio(1)
        .columnsTemplate('1fr 1fr 1fr 1fr').rowsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(SpacingTokens.xs).rowsGap(SpacingTokens.xs)
        .padding(SpacingTokens.sm).backgroundColor(SemanticColors.boardBg).borderRadius(RadiusTokens.lg)

      Column({ space: SpacingTokens.sm }) {
        Row({ space: SpacingTokens.sm }) {
          ForEach(this.vm.state.tray, (value: number) => {
            Button({ type: ButtonType.Normal }) {
              Image(ExpansionArt.equipment(value - 1)).width('100%').height('100%').objectFit(ImageFit.Contain)
                .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
            }.layoutWeight(1).height($r('app.float.art_backpack_equipment_height')).padding(SpacingTokens.sm)
              .backgroundColor(this.vm.state.selected === value - 1 ? SemanticColors.selectionSurface : SemanticColors.surface)
              .borderRadius(RadiusTokens.md)
              .border({ width: this.vm.state.selected === value - 1 ? $r('app.float.art_backpack_selection_border') : 0,
                color: SemanticColors.primary })
              .enabled(this.vm.state.outcome === 0).clickEffect(HarmonyMotion.press(this.getUIContext()))
              .accessibilityText(this.packInfo(value - 1))
              .accessibilityDescription(this.vm.state.selected === value - 1 ? $r('app.string.settings_selected') : $r('app.string.settings_unselected'))
              .onClick(() => { Haptics.tap(); this.vm.choose(value - 1); })
          }, (value: number) => value.toString() + (this.vm.state.selected === value - 1 ? ':selected' : ':idle'))
        }.width('100%')
        Text(this.packInfo(this.vm.state.selected)).width('100%').textAlign(TextAlign.Center)
          .fontFamily(FontTokens.family).fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textSecondary)
        Row({ space: SpacingTokens.sm }) {
          Button($r('app.string.expansion_fight')).layoutWeight(1)
            .constraintSize({ minHeight: $r('app.float.expansion_control_height') })
            .fontFamily(FontTokens.family).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textOnPrimary)
            .backgroundColor(SemanticColors.primary).enabled(this.vm.state.outcome === 0)
            .clickEffect(HarmonyMotion.press(this.getUIContext()))
            .onClick(() => { Haptics.tap(); this.vm.tap(100); })
          Button($r('app.string.expansion_undo')).layoutWeight(1)
            .constraintSize({ minHeight: $r('app.float.expansion_control_height') })
            .fontFamily(FontTokens.family).fontSize(FontTokens.sizeBody).fontColor(SemanticColors.textPrimary)
            .backgroundColor(SemanticColors.surface).enabled(this.vm.canUndo)
            .clickEffect(HarmonyMotion.press(this.getUIContext()))
            .onClick(() => { Haptics.tap(); this.vm.undo(); })
        }.width('100%')
      }.width('100%')
    }.width('100%')
  }
  packCellDescription(index: number, value: number): Resource {
    const description: string = resolveString(value > 0 ? this.packInfo(value - 1) : $r('app.string.collection_empty'), this.getUIContext().getHostContext());
    return $r('app.string.expansion_cell', Math.floor(index / 4) + 1, index % 4 + 1, description);
  }
  packInfo(item: number): Resource {
    return [$r('app.string.expansion_pack_sword'), $r('app.string.expansion_pack_shield'), $r('app.string.expansion_pack_potion'), $r('app.string.expansion_pack_boots')][Math.max(0, Math.min(3, item))];
  }
  @Builder
  Tug() {
    Column({ space: SpacingTokens.base }) {
      Text($r('app.string.expansion_tug_position', this.vm.state.data[0])).fontColor(SemanticColors.textPrimary)
      Stack() {
        Image(ExpansionArt.board('tug')).width('100%').height('100%').objectFit(ImageFit.Fill).accessibilityLevel('no')
        Row() {
          Image(ExpansionArt.person(0)).width($r('app.float.art_tug_character')).height($r('app.float.art_tug_character')).objectFit(ImageFit.Contain)
          Line().layoutWeight(1).height(3).startPoint([0, 1]).endPoint([160, 1]).strokeWidth(3).stroke(SemanticColors.warning)
          Image(ExpansionArt.person(1)).width($r('app.float.art_tug_character')).height($r('app.float.art_tug_character')).objectFit(ImageFit.Contain)
        }.width('90%').translate({ x: (this.vm.state.data[0] - 50) * 0.7 }).animation({ duration: 120 })
      }.width('100%').height($r('app.float.art_banner_height')).clip(true).borderRadius(RadiusTokens.base).hitTestBehavior(HitTestMode.None)
      Progress({ value: this.vm.state.data[0], total: 100, type: ProgressType.Linear }).width('100%').color(SemanticColors.primary)
      Row({ space: SpacingTokens.sm }) {
        Button($r('app.string.expansion_player', 1)).layoutWeight(1).height($r('app.float.expansion_control_height'))
          .onClick(() => { this.vm.tap(0); })
        Button($r('app.string.expansion_player', 2)).layoutWeight(1).height($r('app.float.expansion_control_height'))
          .onClick(() => { this.vm.tap(1); })
      }.width('100%')
    }.width('100%')
  }
  @Builder
  Dots() {
    Column({ space: SpacingTokens.xs }) {
      Text($r('app.string.expansion_turn', this.vm.state.cursor + 1)).fontColor(SemanticColors.textPrimary)
      ForEach(range(this.vm.state.rows + 1), (row: number) => {
        Row({ space: 0 }) {
          ForEach(range(this.vm.state.cols), (col: number) => {
            Text('●').fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textPrimary)
            Button('━', { type: ButtonType.Normal }).layoutWeight(1).height(26).padding(0)
              .fontColor(this.vm.state.board[row * this.vm.state.cols + col] === 0 ? SemanticColors.border : this.vm.state.board[row * this.vm.state.cols + col] === 1 ? SemanticColors.primary : SemanticColors.errorText)
              .backgroundColor(SemanticColors.boardBg).onClick(() => { this.vm.tap(row * this.vm.state.cols + col); })
          }, (col: number) => col.toString())
          Text('●').fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textPrimary)
        }.width('100%')
        if (row < this.vm.state.rows) {
          Row({ space: 0 }) {
            ForEach(range(this.vm.state.cols + 1), (col: number) => {
              Button('┃', { type: ButtonType.Normal }).width(20).height(48).padding(0).backgroundColor(SemanticColors.boardBg)
                .fontColor(this.vm.state.board[this.vm.state.cols * (this.vm.state.cols + 1) + row * (this.vm.state.cols + 1) + col] === 0 ? SemanticColors.border : this.vm.state.board[this.vm.state.cols * (this.vm.state.cols + 1) + row * (this.vm.state.cols + 1) + col] === 1 ? SemanticColors.primary : SemanticColors.errorText)
                .onClick(() => { this.vm.tap(this.vm.state.cols * (this.vm.state.cols + 1) + row * (this.vm.state.cols + 1) + col); })
              if (col < this.vm.state.cols) { Text(this.vm.state.data[row * this.vm.state.cols + col] === 0 ? '' : this.vm.state.data[row * this.vm.state.cols + col].toString()).layoutWeight(1).textAlign(TextAlign.Center).fontColor(SemanticColors.primary) }
            }, (col: number) => col.toString())
          }.width('100%')
        }
      }, (row: number) => row.toString())
    }.width('100%').padding(SpacingTokens.sm).backgroundColor(SemanticColors.boardBg).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
  }
}
