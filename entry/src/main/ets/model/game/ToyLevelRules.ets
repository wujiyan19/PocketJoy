import { ExpansionPiece, ExpansionState } from './ExpansionState';
import { RandomSource, SeededRandom } from './RandomSource';

export class ToyLevelRandom {
  static seed(random: RandomSource): number { return 1 + Math.min(999998, Math.max(0, Math.floor(random.next() * 999999))); }
  static pick(random: RandomSource, count: number): number { return Math.min(count - 1, Math.max(0, Math.floor(random.next() * count))); }
}

/** The seed describes the whole deal, so saving does not reroll geometry or colors. */
export class BlackholeLevels {
  static start(s: ExpansionState, random: RandomSource): void { BlackholeLevels.build(s, ToyLevelRandom.seed(random)); }
  private static build(s: ExpansionState, seed: number): void {
    const random: SeededRandom = new SeededRandom(seed);
    s.goal = 35 + s.level * 10; s.data = [1, seed];
    const player: ExpansionPiece = new ExpansionPiece(); player.id = s.serial++; player.kind = 8;
    player.x = 180; player.y = 230; player.w = player.x; player.h = player.y; player.r = 19; player.color = 1; s.pieces.push(player);
    const cells: number[] = [];
    for (let i: number = 0; i < 56; i++) { cells.push(i); }
    for (let i: number = cells.length - 1; i > 0; i--) {
      const j: number = ToyLevelRandom.pick(random, i + 1); const value: number = cells[i]; cells[i] = cells[j]; cells[j] = value;
    }
    for (let i: number = 0; i < s.goal; i++) {
      const item: ExpansionPiece = new ExpansionPiece(); item.id = s.serial++; item.kind = 9;
      item.r = 8 + Math.floor(i / 8) * 4;
      // Every centre remains reachable even when the hole grows to its maximum radius.
      item.x = 40 + cells[i] % 7 * 46 + ToyLevelRandom.pick(random, 7) - 3;
      item.y = 48 + Math.floor(cells[i] / 7) * 52 + ToyLevelRandom.pick(random, 7) - 3;
      item.color = 1 + i % 6; s.pieces.push(item);
    }
    // A complete witness route chooses a reachable, currently edible object at each step.
    let x: number = player.x; let y: number = player.y; let radius: number = player.r;
    let distance: number = 0;
    while (s.target.length < s.goal) {
      const edible: ExpansionPiece[] = s.pieces.filter((p: ExpansionPiece) => p.kind === 9 &&
        !s.target.includes(p.id) && p.r < radius * 0.9);
      edible.sort((a: ExpansionPiece, b: ExpansionPiece) => Math.hypot(a.x - x, a.y - y) - Math.hypot(b.x - x, b.y - y));
      const item: ExpansionPiece = edible[0];
      const tx: number = Math.max(radius, Math.min(360 - radius, item.x));
      const ty: number = Math.max(radius, Math.min(460 - radius, item.y));
      distance += Math.hypot(tx - x, ty - y); x = tx; y = ty;
      radius = Math.min(70, radius + 1.3); s.target.push(item.id);
    }
    // Allow 0.6s to recognize/retarget each object plus an explicit human-time margin.
    s.data.push(Math.max(120 - s.level * 20, Math.ceil(distance / 145 + s.goal * 0.6 + 12)));
  }
  static limit(s: ExpansionState): number { return s.data.length === 3 ? s.data[2] : 120 - s.level * 20; }
  static valid(s: ExpansionState): boolean {
    if (s.data.length === 0) { return s.target.length === 0; } // already saved legacy round
    if (s.data.length !== 3 || s.data[0] !== 1 || !Number.isInteger(s.data[1]) || s.data[1] < 1 || s.data[1] > 999999) { return false; }
    const expected: ExpansionState = new ExpansionState(); expected.level = s.level; BlackholeLevels.build(expected, s.data[1]);
    if (s.goal !== expected.goal || s.serial !== expected.serial || s.data[2] !== expected.data[2] ||
      s.target.join(',') !== expected.target.join(',') || s.pieces.length + s.moves !== s.goal + 1) { return false; }
    const player: ExpansionPiece = s.pieces[0];
    if (Math.abs(player.r - Math.min(70, 19 + s.moves * 1.3)) > 0.0001 || player.w < 0 || player.w > 360 || player.h < 0 || player.h > 460) { return false; }
    for (let i: number = 1; i < s.pieces.length; i++) {
      const p: ExpansionPiece = s.pieces[i]; const original: ExpansionPiece | undefined = expected.pieces.find((q: ExpansionPiece) => q.id === p.id);
      if (!original || p.x !== original.x || p.y !== original.y || p.r !== original.r || p.color !== original.color || p.vx !== 0 || p.vy !== 0) { return false; }
    }
    return true;
  }
}

/** Smooth random bends whose lateral speed stays below the car's available steering speed. */
export class DriftLevels {
  static modern(s: ExpansionState): boolean { return s.data.length === 5 && s.data[3] === 1; }
  static speed(s: ExpansionState): number { return DriftLevels.modern(s) ? 78 + s.level * 8 : 85; }
  static halfWidth(s: ExpansionState): number { return DriftLevels.modern(s) ? 74 - s.level * 6 : 65; }
  static center(s: ExpansionState, time: number): number {
    if (!DriftLevels.modern(s)) { return 180 + Math.sin(time * 0.65) * 90; }
    const t: number = Math.max(0, time); const index: number = Math.min(s.board.length - 2, Math.floor(t / 4));
    const part: number = Math.min(1, (t - index * 4) / 4); const smooth: number = part * part * (3 - 2 * part);
    return s.board[index] + (s.board[index + 1] - s.board[index]) * smooth;
  }
  static start(s: ExpansionState, random: RandomSource): void { DriftLevels.build(s, ToyLevelRandom.seed(random)); }
  private static build(s: ExpansionState, seed: number): void {
    const random: SeededRandom = new SeededRandom(seed);
    s.goal = 30 + s.level * 10; s.data = [0, 0, 180, 1, seed]; s.board = [];
    let x: number = 145 + ToyLevelRandom.pick(random, 71); s.board.push(x, x);
    for (let i: number = 2; i < Math.ceil((s.goal + 6) / 4) + 1; i++) {
      let delta: number = (36 + ToyLevelRandom.pick(random, 29)) * (random.next() < 0.5 ? -1 : 1);
      if (x + delta < 110 || x + delta > 250) { delta = -delta; }
      x = Math.max(110, Math.min(250, x + delta)); s.board.push(x);
    }
    const car: ExpansionPiece = s.pieces[0]; car.x = s.board[0]; car.r = 20;
    car.vx = (random.next() < 0.5 ? -1 : 1) * DriftLevels.speed(s); s.data[2] = car.x;
  }
  static step(s: ExpansionState, dt: number): void {
    const car: ExpansionPiece = s.pieces[0]; const center: number = DriftLevels.center(s, s.time);
    const ramp: number = DriftLevels.modern(s) ? Math.min(1, 0.35 + s.time * 0.65) : 1;
    car.x += car.vx * ramp * dt; s.data[2] = Math.round(center);
    const footprint: number = DriftLevels.modern(s) ? car.r : 0;
    if (Math.abs(car.x - center) + footprint > DriftLevels.halfWidth(s)) { s.outcome = 2; }
    else if (s.time >= s.goal) { s.outcome = 1; }
    s.score = Math.floor(Math.min(s.time, s.goal) * 50);
  }
  static valid(s: ExpansionState): boolean {
    if (!DriftLevels.modern(s)) { return s.data.length === 3 && s.board.length === 0; }
    if (!Number.isInteger(s.data[4]) || s.data[4] < 1 || s.data[4] > 999999) { return false; }
    const expected: ExpansionState = new ExpansionState(); expected.level = s.level; expected.pieces.push(new ExpansionPiece());
    DriftLevels.build(expected, s.data[4]);
    return s.board.join(',') === expected.board.join(',') && s.pieces[0].r === 20 &&
      Math.abs(s.pieces[0].vx) === DriftLevels.speed(s) && Math.abs(s.data[2] - DriftLevels.center(s, s.time)) <= 1;
  }
}
