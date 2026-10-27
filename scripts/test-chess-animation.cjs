/* Presentation/lifecycle regressions. Native easing and rendered frames are checked separately. */
const assert = require('node:assert/strict');
const { fixture } = require('./test-performance.cjs');
const tests = [];
const test = (name, run) => tests.push({ name, run });
function game(id = 'chess') {
  const f = fixture(), vm = f.vm('ExpansionViewModel');
  vm.init(id); vm.startGame();
  return { f, vm };
}
function position(vm, entries, cursor = 0) {
  const state = vm.model.state;
  state.board.fill(0);
  for (const [cell, piece] of entries) state.board[cell] = piece;
  state.cursor = cursor; vm.sync(false);
}
const moves = vm => vm.chessMoves.map(move => [move.from, move.to, move.piece]);
const finish = vm => vm.finishChessAnimation(vm.chessAnimationSerial);

for (const id of ['chess', 'xiangqi']) {
  const from = id === 'chess' ? 52 : 54, to = id === 'chess' ? 36 : 45;
  test(`${id}: selection is immediate; both sides animate exactly one committed move`, () => {
    const { f, vm } = game(id), board = vm.state.board.slice();
    vm.tap(from); assert.equal(vm.chessAnimating, false); assert(vm.legalTargets.includes(to));
    vm.tap(to);
    assert.equal(vm.chessAnimating, true); assert.deepEqual(moves(vm), [[from, to, board[from]]]);
    assert.deepEqual(vm.chessBoardBefore, board); assert.equal(vm.state.moves, 1);
    assert.equal(vm.computerThinking, true); assert.equal(f.clock.count(), 0);
    const committed = JSON.stringify(vm.state);
    vm.tap(0); vm.choose(0); vm.onAppShown(); f.clock.advance(5000);
    assert.equal(JSON.stringify(vm.state), committed); assert.equal(f.clock.count(), 0);
    finish(vm); assert.equal(vm.chessAnimating, false); assert.equal(f.clock.count(), 1);
    f.clock.advance(499); assert.equal(vm.state.moves, 1);
    f.clock.advance(1); assert.equal(vm.state.moves, 2); assert.equal(vm.chessAnimating, true);
    assert.equal(vm.chessMoves.length, 1); assert(vm.chessMoves[0].piece > 10);
    assert.equal(f.clock.count(), 0); finish(vm); assert.equal(vm.chessAnimating, false);
    vm.dispose();
  });
  for (const action of ['pause', 'background', 'exit', 'undo', 'restart', 'difficulty', 'dispose']) {
    test(`${id}: ${action} cancels a lifted piece and rejects stale completion callbacks`, () => {
      const { f, vm } = game(id); vm.tap(from); vm.tap(to);
      const serial = vm.chessAnimationSerial;
      if (action === 'pause') vm.togglePause();
      else if (action === 'background') vm.onAppHidden();
      else if (action === 'exit') vm.requestBack();
      else if (action === 'undo') vm.undo();
      else if (action === 'restart') vm.startGame();
      else if (action === 'difficulty') vm.changeDifficulty('hard');
      else vm.dispose();
      assert.equal(vm.chessAnimating, false); assert.deepEqual(vm.chessMoves, []);
      assert.equal(f.clock.count(), 0); vm.finishChessAnimation(serial); assert.equal(f.clock.count(), 0);
      f.clock.advance(2000);
      if (action === 'pause' || action === 'background' || action === 'exit') {
        if (action === 'pause') vm.togglePause();
        else if (action === 'background') vm.onAppShown();
        else vm.dismissExitConfirm();
        assert.equal(f.clock.count(), 1); f.clock.advance(500); assert.equal(vm.state.moves, 2);
      }
      vm.dispose();
    });
  }
  test(`${id}: saving during flight restores the committed board without transient animation`, () => {
    const { vm } = game(id); vm.tap(from); vm.tap(to);
    const payload = vm.exportContinuation();
    assert(!payload.includes('chessAnimation')); assert(!payload.includes('chessBoardBefore'));
    const target = game(id); assert(target.vm.importContinuation(payload));
    assert.equal(target.vm.chessAnimating, false); assert.deepEqual(target.vm.state.board, vm.state.board);
    assert.equal(target.f.clock.count(), 1);
    vm.dispose(); target.vm.dispose();
  });
}
for (const [from, to, rookFrom, rookTo, side] of [[60, 62, 63, 61, 0], [60, 58, 56, 59, 0], [4, 6, 7, 5, 1], [4, 2, 0, 3, 1]]) {
  test(`castling ${from}-${to}: king and rook retain their separate paths`, () => {
    const { vm } = game();
    position(vm, [[60, 1], [4, 11], [rookFrom, side === 0 ? 3 : 13]], side);
    const before = vm.state;
    vm.model.chess.move(vm.model.state, from, to); vm.sync();
    assert.deepEqual(moves(vm).sort((a, b) => a[0] - b[0]),
      [[from, to, side === 0 ? 1 : 11], [rookFrom, rookTo, side === 0 ? 3 : 13]].sort((a, b) => a[0] - b[0]));
    assert.deepEqual(vm.chessBoardBefore, before.board); finish(vm); vm.dispose();
  });
}
test('en passant moves only the capturing pawn and retains the captured pawn until landing', () => {
  const { vm } = game(); position(vm, [[60, 1], [4, 11], [28, 6], [27, 16]]);
  vm.model.state.data[6] = 20; vm.sync(false); vm.tap(28); vm.tap(19);
  assert.deepEqual(moves(vm), [[28, 19, 6]]);
  assert.equal(vm.chessBoardBefore[27], 16); assert.equal(vm.state.board[27], 0);
  finish(vm); vm.dispose();
});
for (const side of [0, 1]) for (const choice of [2, 3, 4, 5]) {
  test(`promotion side ${side}, type ${choice}: pawn travels before changing appearance`, () => {
    const { vm } = game(), from = side === 0 ? 8 : 55, to = side === 0 ? 0 : 63;
    position(vm, [[60, 1], [4, 11], [from, side === 0 ? 6 : 16]], side);
    vm.model.state.data[9] = choice; vm.sync(false);
    vm.model.chess.move(vm.model.state, from, to); vm.sync();
    assert.deepEqual(moves(vm), [[from, to, side === 0 ? 6 : 16]]);
    assert.equal(vm.state.board[to], side === 0 ? choice : 12); finish(vm); vm.dispose();
  });
}
test('a final checkmating move still owns an animation after the game stops', () => {
  const { f, vm } = game(); position(vm, [[63, 11], [45, 1], [53, 2]]);
  vm.tap(53); vm.tap(54);
  assert.equal(vm.state.outcome, 1); assert.equal(vm.isFinished, true); assert.equal(vm.chessAnimating, true);
  assert.deepEqual(moves(vm), [[53, 54, 2]]); assert.equal(f.clock.count(), 0);
  finish(vm); assert.equal(vm.chessAnimating, false); assert.equal(f.clock.count(), 0); vm.dispose();
});
test('capture keeps the victim at its old square in the presentation snapshot', () => {
  const { vm } = game(); position(vm, [[60, 1], [4, 11], [40, 3], [32, 16]]);
  vm.tap(40); vm.tap(32); assert.deepEqual(moves(vm), [[40, 32, 3]]);
  assert.equal(vm.chessBoardBefore[32], 16); assert.equal(vm.state.board[32], 3);
  finish(vm); vm.dispose();
});
let failed = 0;
for (const entry of tests) {
  try { entry.run(); }
  catch (error) { failed++; console.error(`FAIL ${entry.name}\n${error.stack}`); }
}
console.log(`${tests.length - failed}/${tests.length} chess animation checks passed.`);
process.exitCode = failed ? 1 : 0;
