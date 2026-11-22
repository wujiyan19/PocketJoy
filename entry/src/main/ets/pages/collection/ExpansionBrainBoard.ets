import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ExpansionRenderPiece } from '../../viewmodel/ExpansionRenderPiece';
import { ExpansionTonePlayer } from '../../common/ExpansionTonePlayer';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { range } from '../../common/Range';
import { ExpansionArt } from '../../common/ExpansionArt';
import { GameSound, gameSound } from '../../common/GameSound';

@ComponentV2
export struct ExpansionBrainBoard {
  @Local pictureGuides: boolean = false;
  @Param gameId: string = '';
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Param beatAreaLimit: number = 360;
  @Local arenaWidth: number = 320;
  @Local audioReady: boolean = false;
  @Local audioFailed: boolean = false;
  @Local sound: GameSound = gameSound;
  private tones: ExpansionTonePlayer = new ExpansionTonePlayer();
  aboutToAppear(): void {
    if (this.gameId === 'melody') {
      if (this.sound.enabled) { this.prepareAudio(); }
      this.vm.setToneCallbacks((note: number): void => { this.tones.play(note); }, (): void => { this.tones.stop(); });
    }
  }
  @Monitor('sound.enabled', 'sound.volume')
  soundChanged(): void {
    if (this.gameId !== 'melody') { return; }
    if (!this.sound.enabled || this.sound.volume === GameSound.MIN_VOLUME) { this.tones.stop(); }
    else if (!this.audioReady) { this.prepareAudio(); }
    else { this.tones.setVolume(); }
  }
  prepareAudio(): void {
    this.tones.dispose(); this.tones = new ExpansionTonePlayer(); this.audioReady = false; this.audioFailed = false;
    this.tones.onReady = (ready: boolean): void => { this.audioReady = ready; this.audioFailed = !ready; };
    const context = this.getUIContext().getHostContext(); if (context) { this.tones.init(context.resourceManager); } else { this.audioFailed = true; }
  }
  aboutToDisappear(): void { if (this.gameId === 'melody') { this.vm.setToneCallbacks((note: number): void => {}, (): void => {}); this.tones.dispose(); } }
  arenaScale(): number { return this.arenaWidth / 360; }
  pictureArt(): Resource {
    const images: Resource[] = [$r('app.media.exp_puzzle_landscape_0'), $r('app.media.exp_puzzle_landscape_1'),
      $r('app.media.exp_puzzle_landscape_2'), $r('app.media.exp_puzzle_landscape_3')];
    return images[this.vm.state.variant ?? 0];
  }
  measure(area: Area): void { const width: number = Number(area.width); if (Number.isFinite(width) && width > 0) { this.arenaWidth = width; } }
  color(index: number): Resource { return [$r('app.color.expansion_color_1'), $r('app.color.expansion_color_2'), $r('app.color.expansion_color_3'), $r('app.color.expansion_color_4')][index % 4]; }
  build() {
    Column({ space: SpacingTokens.base }) {
      if (this.gameId === 'picturepuzzle') { this.Picture() }
      if (this.gameId === 'beatjump') {
        Stack({ alignContent: Alignment.Top }) {
          Stack() {
            this.Arena()
            if (this.vm.state.phase === 0) { Button($r('app.string.expansion_ready')).onClick(() => { this.vm.activate(); }) }
          }.width('100%')
          Column() {
            Text($r('app.string.expansion_beat_time', Math.max(0, Math.round(this.vm.state.cooldown * 1000)))).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary).id('beatjump-countdown')
            Text(this.vm.state.target.slice(this.vm.state.cursor, this.vm.state.cursor + 4).map((v: number) => ['←', '●', '→'][v]).join('   ')).fontSize(FontTokens.sizeTitle).fontColor(SemanticColors.primary).id('beatjump-cues')
          }.align(Alignment.Top).hitTestBehavior(HitTestMode.None)
        }.width('100%').constraintSize({ maxWidth: this.beatAreaLimit }).id('rhythm-three-board')
      }
      if (this.gameId === 'melody') { this.Melody() }
      if (this.gameId === 'beatjump') {
        Row({ space: SpacingTokens.sm }) { ForEach(range(3), (lane: number) => { Button(['←', '●', '→'][lane]).layoutWeight(1).height($r('app.float.expansion_control_height')).id('beatjump-key-' + lane).onClick(() => { this.vm.tap(lane); }) }, (lane: number) => lane.toString()) }.width('100%')
      }
    }.width('100%').padding(SpacingTokens.sm).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
  }
  @Builder
  Picture() {
    Column({ space: SpacingTokens.sm }) {
      Row({ space: SpacingTokens.md }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(this.pictureArt()).width('100%').height('100%').objectFit(ImageFit.Fill)
          if (this.pictureGuides) {
            Column() {
              ForEach(range(this.vm.state.rows), (r: number) => {
                Row() {
                  ForEach(range(this.vm.state.cols), (c: number) => {
                    Column().layoutWeight(1).height('100%').border({ width: 0.5, color: Color.White })
                  }, (c: number) => c.toString())
                }.width('100%').layoutWeight(1)
              }, (r: number) => r.toString())
            }.width('100%').height('100%').id('picture-guide-lines').hitTestBehavior(HitTestMode.None)
          }
        }.width('38%').aspectRatio(1).borderRadius(RadiusTokens.sm).clip(true)
        Button($r('app.string.picture_reference_grid'), { buttonStyle: ButtonStyleMode.TEXTUAL }).id('picture-guides')
          .accessibilityDescription(this.pictureGuides ? $r('app.string.settings_selected') : $r('app.string.settings_unselected'))
          .onClick(() => { this.pictureGuides = !this.pictureGuides; })
      }.width('100%').justifyContent(FlexAlign.Center)
      Column({ space: 0 }) {
        ForEach(range(this.vm.state.rows), (row: number) => {
          Row({ space: 0 }) {
            ForEach(range(this.vm.state.cols), (col: number) => {
              Stack({ alignContent: Alignment.TopStart }) {
                Image(this.pictureArt()).width(this.arenaWidth).height(this.arenaWidth).objectFit(ImageFit.Fill)
                  .id('picture-image-' + this.vm.state.board[row * this.vm.state.cols + col])
                  .translate({ x: -(this.vm.state.board[row * this.vm.state.cols + col] % this.vm.state.cols) * this.arenaWidth / this.vm.state.cols,
                    y: -Math.floor(this.vm.state.board[row * this.vm.state.cols + col] / this.vm.state.cols) * this.arenaWidth / this.vm.state.cols }).hitTestBehavior(HitTestMode.None)
              }.width(this.arenaWidth / this.vm.state.cols).height(this.arenaWidth / this.vm.state.cols).clip(true)
                .id('picture-tile-' + (row * this.vm.state.cols + col))
                .border({ width: this.vm.state.selected === row * this.vm.state.cols + col ? 3 : 1, color: this.vm.state.selected === row * this.vm.state.cols + col ? SemanticColors.primary : SemanticColors.surface })
                .onClick(() => { this.vm.tap(row * this.vm.state.cols + col); })
            }, (col: number) => col.toString())
          }.width('100%')
        }, (row: number) => row.toString())
      }.width('100%').aspectRatio(1).onAreaChange((oldArea: Area, area: Area) => { this.measure(area); })
    }.width('100%')
  }
  @Builder
  ArenaPieces() {
    ForEach(this.vm.worldPieces, (rendered: ExpansionRenderPiece) => {
      Image(ExpansionArt.piece(this.gameId, rendered.piece)).width(rendered.piece.r * 2 * this.arenaScale()).height(rendered.piece.r * 2 * this.arenaScale()).objectFit(ImageFit.Contain)
        .translate({ x: (rendered.piece.x - rendered.piece.r) * this.arenaScale(), y: (rendered.piece.y - rendered.piece.r) * this.arenaScale() }).hitTestBehavior(HitTestMode.None)
    }, (rendered: ExpansionRenderPiece) => rendered.id.toString())
  }
  @Builder
  Arena() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.gameId === 'beatjump') { ForEach(range(3), (lane: number) => { Column().width(72 * this.arenaScale()).height(18 * this.arenaScale()).backgroundColor(this.color(lane)).translate({ x: (24 + lane * 120) * this.arenaScale(), y: 370 * this.arenaScale() }) }, (lane: number) => lane.toString()) }
      this.ArenaPieces()
    }.width('100%').aspectRatio(360 / 460).clip(true).backgroundColor(SemanticColors.boardBg).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
      .onAreaChange((oldArea: Area, area: Area) => { this.measure(area); })
  }
  @Builder
  Melody() {
    Column({ space: SpacingTokens.base }) {
      Text(this.vm.state.phase === 1 ? $r('app.string.expansion_listen') : $r('app.string.expansion_repeat_melody')).fontColor(SemanticColors.textPrimary)
      Row({ space: SpacingTokens.sm }) {
        ForEach(range(this.vm.state.target.length), (slot: number) => {
          Column().width(15).height(15).borderRadius(RadiusTokens.full)
            .border({ width: this.vm.state.phase === 1 && this.vm.state.cursor - 1 === slot ? 3 : 1, color: SemanticColors.primary })
            .backgroundColor(this.vm.state.phase === 0 && slot < this.vm.state.data[0] ? SemanticColors.primary : SemanticColors.surface)
            .id(this.vm.state.phase === 1 && this.vm.state.cursor - 1 === slot ? 'melody-current-' + slot :
              this.vm.state.phase === 0 && slot < this.vm.state.data[0] ? 'melody-entered-' + slot : 'melody-slot-' + slot)
        }, (slot: number) => slot.toString())
      }.justifyContent(FlexAlign.Center).width('100%')
      Row({ space: SpacingTokens.sm }) {
        ForEach(range(4), (note: number) => {
          Stack() {
            Button(['C', 'D', 'E', 'G'][note], { type: ButtonType.Normal }).width('100%').height('100%').fontSize(FontTokens.sizeTitle)
              .backgroundColor(this.color(note)).borderRadius(RadiusTokens.base).id('melody-key-' + note)
              .enabled(this.vm.state.phase === 0 && this.vm.state.cursor >= this.vm.state.target.length && (this.audioReady || !this.sound.enabled))
              .onClick(() => { this.vm.tap(note); })
            if (this.vm.state.phase === 1 && this.vm.state.selected === note && this.vm.state.cooldown > 0.13) {
              Column().width('92%').height('94%').borderRadius(RadiusTokens.md).border({ width: 3, color: SemanticColors.primary })
                .scale({ x: 0.91 + 0.09 * this.vm.state.cooldown / 0.55, y: 0.91 + 0.09 * this.vm.state.cooldown / 0.55 })
                .id('melody-lit-' + note).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
            }
          }.layoutWeight(1).height(105 + note * 8)
        }, (note: number) => note.toString())
      }.width('100%')
      if (!this.sound.enabled) { Text($r('app.string.settings_sound_muted')).fontColor(SemanticColors.textSecondary) }
      else if (this.audioFailed) { Button($r('app.string.expansion_audio_retry')).onClick(() => { this.prepareAudio(); }) }
      else if (!this.audioReady) { Text($r('app.string.expansion_audio_loading')).fontColor(SemanticColors.textSecondary) }
      Button($r('app.string.expansion_play_melody')).id('melody-play').enabled(this.vm.state.phase === 0 && (this.audioReady || !this.sound.enabled)).onClick(() => { this.vm.tap(900); })
    }.width('100%')
  }
}
