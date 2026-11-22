/** These numeric codes are part of the saved game format. */
export enum ExpansionPieceKind {
  Actor = 24,
  Platform = 25,
  Wall = 26,
  Goal = 27,
  Anchor = 28,
  FlightGate = 29,
  Fruit = 30,
  Hazard = 31,
  Ball = 32,
  Enemy = 33,
  Projectile = 34,
  Vehicle = 36,
  Paddle = 39
}

export enum ChessDataIndex {
  EnPassant = 6,
  HalfMoves = 7,
  Draw = 8,
  Promotion = 9
}
