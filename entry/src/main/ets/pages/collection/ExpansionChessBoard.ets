import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ChessPieceMove } from '../../viewmodel/ChessPieceMove';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { HarmonyMotion } from '../../common/HarmonyMotion';
import { ExpansionArt } from '../../common/ExpansionArt';
import { range } from '../../common/Range';
import { GameArtTile } from '../../components/GameArtTile';

@ComponentV2
export struct ExpansionChessBoard {
  @Param gameId: string = '';
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  @Local boardWidth: number = 320;
  @Local boardHeight: number = 320;
  @Local moving: ChessPieceMove[] = [];
  @Local before: number[] = [];
  @Local progress: number = 0;
  @Local pieceScale: number = 1;
  @Local lift: number = 0;
  @Local captureOpacity: number = 1;
  @Local active: boolean = false;
  private mounted: boolean = false;
  private startTimer: number = -1;
  private generation: number = 0;
  private moveSerial: number = -1;
  private gap: number = 1;
  private liftScale: number = 1.16;
  private liftOffset: number = -5;
  private pickupDuration: number = 90;
  private travelDuration: number = 260;
  private travelPerCell: number = 24;
  private maxTravelDuration: number = 420;
  private landingDuration: number = 130;

  aboutToAppear(): void {
    this.mounted = true;
    const context = this.getUIContext();
    this.gap = HarmonyMotion.value(context, $r('app.float.chess_board_gap'), 1);
    this.liftScale = HarmonyMotion.value(context, $r('app.float.chess_move_lift_scale'), 1.16);
    this.liftOffset = HarmonyMotion.value(context, $r('app.float.chess_move_lift_offset'), -5);
    this.pickupDuration = HarmonyMotion.value(context, $r('app.float.chess_move_pickup_duration'), 90);
    this.travelDuration = HarmonyMotion.value(context, $r('app.float.chess_move_travel_duration'), 260);
    this.travelPerCell = HarmonyMotion.value(context, $r('app.float.chess_move_travel_per_cell'), 24);
    this.maxTravelDuration = HarmonyMotion.value(context, $r('app.float.chess_move_max_travel_duration'), 420);
    this.landingDuration = HarmonyMotion.value(context, $r('app.float.chess_move_landing_duration'), 130);
    this.animationChanged();
  }
  aboutToDisappear(): void {
    this.mounted = false; this.cancel(); this.vm.finishChessAnimation(this.moveSerial);
  }
  cancel(): void {
    this.generation++;
    if (this.startTimer >= 0) { clearTimeout(this.startTimer); this.startTimer = -1; }
    this.active = false;
    this.getUIContext().animateTo({ duration: 0 }, () => {
      this.progress = 0; this.pieceScale = 1; this.lift = 0; this.captureOpacity = 1;
    });
  }
  @Monitor('vm.chessAnimationSerial')
  animationChanged(): void {
    if (!this.mounted) { return; }
    this.cancel();
    if (!this.vm.chessAnimating) { return; }
    this.moveSerial = this.vm.chessAnimationSerial;
    this.moving = this.vm.chessMoves.slice(); this.before = this.vm.chessBoardBefore.slice(); this.active = true;
    const generation: number = this.generation;
    const serial: number = this.moveSerial;
    // Mount the overlay at its source before starting compositor-only keyframes.
    this.startTimer = setTimeout(() => {
      this.startTimer = -1;
      if (!this.mounted || generation !== this.generation || serial !== this.vm.chessAnimationSerial) { return; }
      this.getUIContext().keyframeAnimateTo({ iterations: 1, onFinish: () => {
        if (!this.mounted || generation !== this.generation || serial !== this.vm.chessAnimationSerial) { return; }
        this.active = false; this.vm.finishChessAnimation(serial);
      } }, [
        { duration: this.pickupDuration, curve: Curve.EaseOut, event: () => { this.pieceScale = this.liftScale; this.lift = this.liftOffset; } },
        { duration: this.moveDuration(), curve: Curve.EaseInOut, event: () => { this.progress = 1; } },
        { duration: this.landingDuration, curve: Curve.EaseInOut, event: () => { this.pieceScale = 1; this.lift = 0; this.captureOpacity = 0; } }
      ]);
    }, 16);
  }
  moveDuration(): number {
    let distance: number = 1;
    this.moving.forEach((move: ChessPieceMove) => {
      distance = Math.max(distance, Math.abs(move.to % this.vm.state.cols - move.from % this.vm.state.cols),
        Math.abs(Math.floor(move.to / this.vm.state.cols) - Math.floor(move.from / this.vm.state.cols)));
    });
    return Math.min(this.maxTravelDuration, this.travelDuration + distance * this.travelPerCell);
  }
  measure(area: Area): void {
    const width: number = Number(area.width);
    const height: number = Number(area.height);
    if (Number.isFinite(width) && Number.isFinite(height) && width > 0 && height > 0 &&
      (Math.abs(width - this.boardWidth) > 0.1 || Math.abs(height - this.boardHeight) > 0.1)) {
      // A resize settles the current move instead of changing layout during its animation.
      if (this.active) { this.cancel(); this.vm.finishChessAnimation(this.moveSerial); }
      this.boardWidth = width; this.boardHeight = height;
    }
  }
  cellSize(): number { return (this.boardWidth - (this.vm.state.cols - 1) * this.gap) / this.vm.state.cols; }
  cellHeight(): number { return (this.boardHeight - (this.vm.state.rows - 1) * this.gap) / this.vm.state.rows; }
  coordinate(cell: number, horizontal: boolean): number {
    return (horizontal ? cell % this.vm.state.cols : Math.floor(cell / this.vm.state.cols)) *
      ((horizontal ? this.cellSize() : this.cellHeight()) + this.gap);
  }
  moveOffset(move: ChessPieceMove, horizontal: boolean): number {
    const from: number = this.coordinate(move.from, horizontal);
    return from + (this.coordinate(move.to, horizontal) - from) * this.progress + (horizontal ? 0 : this.lift);
  }
  displayPiece(cell: number): number {
    if (!this.active) { return this.vm.state.board[cell]; }
    return this.moving.some((move: ChessPieceMove) => move.from === cell) ? 0 : this.before[cell];
  }
  cellOpacity(cell: number): number {
    return this.active && this.before[cell] > 0 && this.before[cell] !== this.vm.state.board[cell] ? this.captureOpacity : 1;
  }
  pieceText(piece: number): string {
    if (piece === 0) { return ''; }
    const type: number = piece % 10;
    return this.gameId === 'chess' ? ['', '♚', '♛', '♜', '♝', '♞', '♟'][type] :
      (piece > 10 ? ['', '將', '士', '象', '馬', '車', '砲', '卒'] : ['', '帥', '仕', '相', '馬', '車', '炮', '兵'])[type];
  }
  pieceArt(piece: number): Resource {
    return piece === 0 ? $r('app.media.exp_empty') : this.gameId === 'chess' ? ExpansionArt.chess(piece) : $r('app.media.exp_chip');
  }
  @Builder
  MovingPiece(piece: number) {
    Stack() {
      Image(this.pieceArt(piece)).width('100%').height('100%').objectFit(ImageFit.Fill)
      if (this.gameId === 'xiangqi') {
        Text(this.pieceText(piece)).fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Medium)
          .fontColor(piece > 10 ? SemanticColors.textPrimary : SemanticColors.error).textAlign(TextAlign.Center)
      }
    }.width('100%').height('100%').renderGroup(true).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
  }
  build() {
    Column({ space: SpacingTokens.sm }) {
      Text($r('app.string.expansion_board_opponent')).fontColor(SemanticColors.textSecondary)
      Stack() {
        Stack({ alignContent: Alignment.TopStart }) {
          Column({ space: this.gap }) {
            ForEach(range(this.vm.state.rows), (row: number) => {
              Row({ space: this.gap }) {
                ForEach(range(this.vm.state.cols), (col: number) => {
                  Column() {
                    GameArtTile({ image: this.pieceArt(this.displayPiece(row * this.vm.state.cols + col)),
                      label: this.gameId === 'xiangqi' ? this.pieceText(this.displayPiece(row * this.vm.state.cols + col)) : '',
                      textColor: this.displayPiece(row * this.vm.state.cols + col) > 10 ? SemanticColors.textPrimary : SemanticColors.error,
                      selected: this.vm.state.selected === row * this.vm.state.cols + col,
                      description: $r('app.string.expansion_cell', row + 1, col + 1, this.pieceText(this.vm.state.board[row * this.vm.state.cols + col])),
                      onTap: () => { this.vm.tap(row * this.vm.state.cols + col); } })
                      .opacity(this.cellOpacity(row * this.vm.state.cols + col))
                  }.layoutWeight(1).height('100%').padding(0)
                    .backgroundColor(this.vm.legalTargets.includes(row * this.vm.state.cols + col) ? SemanticColors.primaryLight : (row + col) % 2 === 0 ? SemanticColors.surface : SemanticColors.boardBg)
                    .border({ width: this.vm.state.selected === row * this.vm.state.cols + col ? 2 : 0, color: SemanticColors.primary })
                    .id('chess-cell-' + (row * this.vm.state.cols + col).toString())
                }, (col: number) => col.toString())
              }.width('100%').layoutWeight(1)
            }, (row: number) => row.toString())
          }.width('100%').height('100%')
          if (this.active) {
            ForEach(this.moving, (move: ChessPieceMove) => {
              Column() { this.MovingPiece(move.piece) }
                .width(this.cellSize()).height(this.cellHeight()).renderGroup(true)
                .scale({ x: this.pieceScale, y: this.pieceScale })
                .translate({ x: this.moveOffset(move, true), y: this.moveOffset(move, false) })
                .hitTestBehavior(HitTestMode.None).accessibilityLevel('no').id('chess-moving-' + move.from.toString())
            }, (move: ChessPieceMove) => this.moveSerial.toString() + ':' + move.from.toString())
          }
        }.width('100%').height('100%').onAreaChange((oldArea: Area, area: Area) => { this.measure(area); })
      }.width('100%').aspectRatio(this.vm.state.cols / this.vm.state.rows).padding(SpacingTokens.xs)
        .backgroundColor(SemanticColors.border).borderRadius(RadiusTokens.sm).id('chess-board')
      if (this.gameId === 'chess') {
        Text($r('app.string.expansion_promotion')).fontColor(SemanticColors.textSecondary)
        Row({ space: SpacingTokens.sm }) {
          ForEach(range(4), (choice: number) => {
            Column() { GameArtTile({ image: ExpansionArt.chess(choice + 2), description: ['♛', '♜', '♝', '♞'][choice],
              selected: this.vm.state.data[9] === choice + 2,
              onTap: () => { this.vm.choose(choice); } }) }.layoutWeight(1).height(52)
          }, (choice: number) => choice.toString())
        }.width('100%')
      }
    }.width('100%').hitTestBehavior(this.vm.chessAnimating || this.vm.computerThinking || this.vm.state.outcome !== 0 ? HitTestMode.None : HitTestMode.Default)
  }
}
