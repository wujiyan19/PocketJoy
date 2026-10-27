import { ExpansionState } from '../model/game/ExpansionState';

/** Presentation-only move data; never stored in a game continuation. */
export class ChessPieceMove {
  from: number;
  to: number;
  piece: number;
  constructor(from: number, to: number, piece: number) {
    this.from = from; this.to = to; this.piece = piece;
  }
}

export function chessMovesBetween(before: ExpansionState, after: ExpansionState): ChessPieceMove[] {
  if (before.id !== after.id || after.moves !== before.moves + 1 || before.board.length !== after.board.length) { return []; }
  const result: ChessPieceMove[] = [];
  const side: number = before.cursor + 1;
  for (let from: number = 0; from < before.board.length; from++) {
    const piece: number = before.board[from];
    if (piece === 0 || (piece > 10 ? 2 : 1) !== side || after.board[from] !== 0) { continue; }
    for (let to: number = 0; to < after.board.length; to++) {
      if (before.board[to] === after.board[to] || after.board[to] === 0 || (after.board[to] > 10 ? 2 : 1) !== side) { continue; }
      const promotion: boolean = after.id === 'chess' && piece % 10 === 6 && (to < 8 || to >= 56);
      if (after.board[to] === piece || promotion) { result.push(new ChessPieceMove(from, to, piece)); break; }
    }
  }
  return result;
}
