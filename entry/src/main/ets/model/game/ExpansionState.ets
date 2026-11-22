import { sameNumbers, snapshotNumbers } from './SnapshotArrays';

/** Serializable values only: no timers, native handles or UI references. */
export class ExpansionPiece {
  id: number = 0;
  kind: number = 0;
  x: number = 0;
  y: number = 0;
  w: number = 0;
  h: number = 0;
  r: number = 0;
  color: number = 0;
  owner: number = -1;
  alive: boolean = true;
  vx: number = 0;
  vy: number = 0;
  age: number = 0;
}

export class ExpansionState {
  id: string = '';
  level: number = 1;
  sokobanLevel?: number;
  cols: number = 6;
  rows: number = 6;
  board: number[] = [];
  tray: number[] = [];
  target: number[] = [];
  pieces: ExpansionPiece[] = [];
  piles: ExpansionPile[] = [];
  data: number[] = [];
  score: number = 0;
  moves: number = 0;
  outcome: number = 0;
  selected: number = -1;
  cursor: number = 0;
  errors: number = 0;
  goal: number = 0;
  next: number = 1;
  phase: number = 0;
  serial: number = 1;
  time: number = 0;
  cooldown: number = 0;
  variant: number = 0;
}

export class ExpansionPile { cards: number[] = []; }

function samePiece(a: ExpansionPiece, b: ExpansionPiece): boolean {
  return a === b || (a.id === b.id && a.kind === b.kind && a.x === b.x && a.y === b.y &&
    a.w === b.w && a.h === b.h && a.r === b.r && a.color === b.color && a.owner === b.owner &&
    a.alive === b.alive && a.vx === b.vx && a.vy === b.vy && a.age === b.age);
}

function samePieces(left: ExpansionPiece[], right: ExpansionPiece[]): boolean {
  return left === right || (left.length === right.length && left.every((p: ExpansionPiece, i: number) => samePiece(p, right[i])));
}

function samePiles(left: ExpansionPile[], right: ExpansionPile[]): boolean {
  return left === right || (left.length === right.length && left.every((pile: ExpansionPile, i: number) => sameNumbers(pile.cards, right[i].cards)));
}

export function sameExpansionState(a: ExpansionState, b: ExpansionState): boolean {
  return a === b || (a.time === b.time && a.moves === b.moves && a.score === b.score && a.phase === b.phase &&
    a.selected === b.selected && a.cursor === b.cursor && a.outcome === b.outcome && a.id === b.id &&
    a.level === b.level && a.sokobanLevel === b.sokobanLevel && a.cols === b.cols && a.rows === b.rows &&
    a.errors === b.errors && a.goal === b.goal && a.next === b.next && a.serial === b.serial &&
    a.cooldown === b.cooldown && a.variant === b.variant && sameNumbers(a.board, b.board) &&
    sameNumbers(a.tray, b.tray) && sameNumbers(a.target, b.target) && sameNumbers(a.data, b.data) &&
    samePieces(a.pieces, b.pieces) && samePiles(a.piles, b.piles));
}

export function snapshotExpansion(s: ExpansionState, previous?: ExpansionState): ExpansionState {
  const pieces: ExpansionPiece[] = previous && samePieces(s.pieces, previous.pieces) ? previous.pieces :
    s.pieces.map((p: ExpansionPiece, i: number): ExpansionPiece => {
      const old: ExpansionPiece | undefined = previous?.pieces[i];
      if (old && samePiece(p, old)) { return old; }
      return { id: p.id, kind: p.kind, x: p.x, y: p.y, w: p.w, h: p.h, r: p.r, color: p.color,
        owner: p.owner, alive: p.alive, vx: p.vx, vy: p.vy, age: p.age };
    });
  const piles: ExpansionPile[] = previous && samePiles(s.piles, previous.piles) ? previous.piles :
    s.piles.map((pile: ExpansionPile, i: number): ExpansionPile => {
      const old: ExpansionPile | undefined = previous?.piles[i];
      if (old && sameNumbers(pile.cards, old.cards)) { return old; }
      return { cards: pile.cards.slice() };
    });
  const result: ExpansionState = {
    id: s.id, level: s.level, cols: s.cols, rows: s.rows,
    board: snapshotNumbers(s.board, previous?.board), tray: snapshotNumbers(s.tray, previous?.tray),
    target: snapshotNumbers(s.target, previous?.target), pieces: pieces, piles: piles,
    data: snapshotNumbers(s.data, previous?.data), score: s.score, moves: s.moves,
    outcome: s.outcome, selected: s.selected, cursor: s.cursor, errors: s.errors, goal: s.goal,
    next: s.next, phase: s.phase, serial: s.serial, time: s.time, cooldown: s.cooldown, variant: s.variant
  };
  if (s.sokobanLevel !== undefined) { result.sokobanLevel = s.sokobanLevel; }
  return result;
}

export class BlockShape {
  cols: number = 1;
  rows: number = 1;
  cells: number[] = [0];
  constructor(cols: number, rows: number, cells: number[]) {
    this.cols = cols; this.rows = rows; this.cells = cells;
  }
}

export const BLOCK_SHAPES: BlockShape[] = [
  new BlockShape(1, 1, [0]), new BlockShape(2, 1, [0, 1]), new BlockShape(1, 2, [0, 1]),
  new BlockShape(3, 1, [0, 1, 2]), new BlockShape(1, 3, [0, 1, 2]),
  new BlockShape(2, 2, [0, 1, 2, 3]), new BlockShape(2, 2, [0, 2, 3]),
  new BlockShape(2, 2, [0, 1, 2]), new BlockShape(3, 2, [0, 1, 2, 4]),
  new BlockShape(3, 3, [1, 3, 4, 5, 7])
];
