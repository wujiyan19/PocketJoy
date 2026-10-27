import { Node } from '@kit.ArkGraphics3D';
import { resourceManager } from '@kit.LocalizationKit';
import { ToySceneController } from '../common/ToySceneController';
import { ExpansionViewModel } from '../viewmodel/ExpansionViewModel';
import { ExpansionPiece } from '../model/game/ExpansionState';
import { GameDataManager } from '../model/GameData';
import { FontTokens, SemanticColors, SpacingTokens } from '../common/DesignTokens';

class SwallowSlot {
  body: Node | null = null; shadow: Node | null = null; edible: Node | null = null;
  seen: boolean = false; goneAt: number = -1;
  hidden: boolean = false; canEat: boolean = false;
  x: number = 0; y: number = 0; radius: number = 8;
}

@ComponentV2
export struct ToyBlackholeStage {
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Param heightLimit: number = 460;
  @Local renderer: ToySceneController = new ToySceneController();
  @Local availableWidth: number = 320;
  @Local widthVp: number = 320;
  private hole: Node | null = null;
  private slots: SwallowSlot[] = [];
  private previousTime: number = 0;
  private previousMoves: number = 0;
  private previousDeal: number = -1;

  @Monitor('vm.state')
  update(): void { this.sync(); }
  aboutToAppear(): void { this.load(); }
  aboutToDisappear(): void { this.hole = null; this.slots = []; this.renderer.dispose(); }
  edibleCount(): number {
    const radius: number = this.vm.state.pieces[0]?.r ?? 19;
    return this.vm.state.pieces.filter((p: ExpansionPiece) => p.kind === 9 && p.r < radius * 0.9).length;
  }
  private async load(): Promise<void> {
    const theme: string = GameDataManager.getThemeMode();
    const dark: boolean = theme === 'dark' || (theme === 'system' &&
      this.getUIContext().getHostContext()?.resourceManager.getConfigurationSync().colorMode === resourceManager.ColorMode.DARK);
    const ready: boolean = await this.renderer.load(dark ? $rawfile('toy/blackhole_dark.glb') : $rawfile('toy/blackhole.glb'),
      dark ? { r: 0.014, g: 0.030, b: 0.045, a: 1 } : { r: 0.96, g: 0.94, b: 0.88, a: 1 });
    if (!ready) { return; }
    this.hole = this.renderer.node('hole'); this.slots = [];
    for (let i: number = 0; i < 55; i++) {
      const slot: SwallowSlot = new SwallowSlot();
      slot.body = this.renderer.node('prop' + i); slot.shadow = this.renderer.node('shadow' + i);
      slot.edible = this.renderer.node('edible' + i); this.slots.push(slot);
    }
    this.sync();
  }
  private sync(): void {
    const player: ExpansionPiece | undefined = this.vm.state.pieces[0];
    if (this.hole === null || player === undefined) { return; }
    const time: number = this.vm.state.time;
    const deal: number = this.vm.state.data.length === 3 ? this.vm.state.data[1] : 0;
    const reset: boolean = deal !== this.previousDeal || time < this.previousTime || this.vm.state.moves < this.previousMoves;
    this.previousDeal = deal;
    this.previousTime = time; this.previousMoves = this.vm.state.moves;
    if (reset) { this.slots.forEach((slot: SwallowSlot) => { slot.seen = false; slot.goneAt = -1; slot.hidden = false; }); }
    this.hole.position = { x: player.x - 180, y: 230 - player.y, z: 0 };
    this.hole.scale = { x: player.r / 19, y: player.r / 19, z: 1 };
    const present: boolean[] = new Array<boolean>(55).fill(false);
    for (let i: number = 1; i < this.vm.state.pieces.length; i++) {
      const p: ExpansionPiece = this.vm.state.pieces[i]; const index: number = p.id - 2;
      if (index < 0 || index >= this.slots.length) { continue; }
      const slot: SwallowSlot = this.slots[index]; present[index] = true;
      const first: boolean = !slot.seen;
      // Static props stay in their native slots; only the hole and swallowing props animate.
      if (first) {
        slot.x = p.x; slot.y = p.y; slot.radius = p.r;
        if (slot.body !== null) {
          slot.body.visible = true; slot.body.position = { x: p.x - 180, y: 230 - p.y, z: 1 };
          slot.body.scale = { x: p.r / 16, y: p.r / 16, z: p.r / 16 };
        }
        if (slot.shadow !== null) {
          slot.shadow.visible = true; slot.shadow.position = { x: p.x - 180, y: 230 - p.y, z: 0 };
          slot.shadow.scale = { x: p.r / 16, y: p.r / 16, z: 1 };
        }
        if (slot.edible !== null) {
          slot.edible.position = { x: p.x - 180, y: 230 - p.y, z: 0 };
          slot.edible.scale = { x: p.r / 16, y: p.r / 16, z: 1 };
        }
      }
      const canEat: boolean = p.r < player.r * 0.9;
      if (slot.edible !== null && (first || canEat !== slot.canEat)) { slot.edible.visible = canEat; }
      slot.seen = true; slot.hidden = false; slot.goneAt = -1; slot.canEat = canEat;
    }
    for (let i: number = 0; i < this.slots.length; i++) {
      if (present[i]) { continue; }
      const slot: SwallowSlot = this.slots[i];
      if (slot.hidden) { continue; }
      if (slot.goneAt < 0) {
        if (slot.shadow !== null) { slot.shadow.visible = false; }
        if (slot.edible !== null) { slot.edible.visible = false; }
      }
      if (slot.body === null) { continue; }
      if (!slot.seen || this.vm.state.outcome !== 0) { slot.body.visible = false; slot.hidden = true; continue; }
      if (slot.goneAt < 0) { slot.goneAt = time; }
      const progress: number = Math.min(1, (time - slot.goneAt) / 0.28);
      slot.body.visible = progress < 1;
      slot.hidden = progress >= 1;
      slot.body.position = { x: slot.x + (player.x - slot.x) * progress - 180,
        y: 230 - slot.y - (player.y - slot.y) * progress, z: 1 - slot.radius * 3 * progress };
      const size: number = slot.radius / 16 * (1 - progress * 0.5);
      slot.body.scale = { x: size, y: size, z: size };
    }
    this.renderer.draw();
  }
  private touch(event: TouchEvent): void {
    if (this.renderer.options === undefined) { return; }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.vm.setDragging(false); return; }
    if (event.type === TouchType.Down) { this.vm.setDragging(true); }
    if (event.touches.length > 0 && (event.type === TouchType.Down || event.type === TouchType.Move)) {
      this.vm.aim(event.touches[0].x * 360 / this.widthVp, event.touches[0].y * 360 / this.widthVp);
    }
  }
  build() {
    Column({ space: SpacingTokens.sm }) {
      Text($r('app.string.toy_blackhole_edible', this.edibleCount())).fontSize(FontTokens.sizeCaption)
        .fontColor(SemanticColors.textSecondary)
      Stack() {
        if (this.renderer.options !== undefined) {
          Component3D(this.renderer.options).width('100%').height('100%').renderWidth('80%').renderHeight('80%')
            .hitTestBehavior(HitTestMode.None).accessibilityLevel('no').onAppear(() => { this.sync(); })
          Column().width('100%').height('100%').backgroundColor(Color.Transparent).hitTestBehavior(HitTestMode.Block)
            .onTouch((event: TouchEvent) => { this.touch(event); })
        } else if (this.renderer.failed) {
          Button($r('app.string.toy_scene_retry')).onClick(() => { this.load(); })
        } else {
          Text($r('app.string.toy_scene_loading')).fontColor(SemanticColors.textSecondary)
        }
      }.width(Math.min(this.availableWidth, this.heightLimit * 360 / 460)).aspectRatio(360 / 460)
        .borderRadius($r('app.float.toy_board_radius')).clip(true).id('toy-blackhole-scene')
        .accessibilityText($r('app.string.toy_blackhole_board'))
        .onAreaChange((oldArea: Area, area: Area) => { this.widthVp = Number(area.width); })
      Button($r('app.string.expansion_ready')).enabled(this.renderer.options !== undefined && this.vm.state.phase === 0)
        .visibility(this.vm.state.phase === 0 ? Visibility.Visible : Visibility.Hidden)
        .onClick(() => { this.vm.activate(); })
    }.width('100%').onAreaChange((oldArea: Area, area: Area) => { this.availableWidth = Number(area.width); })
  }
}
