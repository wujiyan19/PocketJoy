const assert = require('node:assert/strict');
const { fixture } = require('./test-performance.cjs');
const { shortestRoute } = require('./test-sokoban-levels.cjs');

function launch(saved = {}) {
  const app = fixture(saved);
  app.data().init({});
  const vm = app.vm('ExpansionViewModel');
  vm.init('sokoban');
  vm.startGame();
  return { app, vm };
}

const { app, vm } = launch();
const levels = app.load('entry/src/main/ets/model/game/SokobanLevels.ets').SOKOBAN_LEVELS;
const data = app.data();
data.updateHighScore('sokoban', 85);
data.recordMode('sokoban', 'normal', 85);

for (let number = 1; number <= levels.length; number++) {
  vm.selectSokobanLevel(number);
  assert.equal(vm.sokobanLevel, number);
  assert.equal(vm.sokobanCompleted, number - 1);
  assert.equal(vm.sokobanUnlocked(), number);
  vm.selectSokobanLevel(number + 1);
  assert.equal(vm.sokobanLevel, number, 'the next level is still locked');
  const start = JSON.stringify(vm.state);
  const rows = levels[number - 1].rows;
  const route = shortestRoute(rows);
  // A shortcut found with one rule disabled must fail through the real controls.
  for (const relaxed of [
    rows.map(row => row.replace(/[<>^v]/g, ' ')),
    rows.map(row => row.replace('A', '$').replace('a', '.'))
  ]) {
    if (relaxed.join('') === rows.join('')) continue;
    for (const direction of shortestRoute(relaxed)) vm.tap(direction);
    assert.equal(vm.state.outcome, 0, 'ignoring an arrow or the marked goal must not win');
    assert.equal(vm.sokobanCompleted, number - 1);
    vm.startGame();
  }
  if (route.length > 1) {
    vm.tap(route[0]);
    vm.undo();
    assert.equal(JSON.stringify(vm.state), start, 'undo restores the opening position');
    vm.tap(route[0]);
    const receiver = app.vm('ExpansionViewModel');
    receiver.init('sokoban');
    assert.ok(receiver.importContinuation(vm.exportContinuation()));
    assert.deepEqual(receiver.state, vm.state, 'level, board and moved boxes transfer together');
    receiver.dispose();
    vm.startGame();
    assert.equal(JSON.stringify(vm.state), start, 'retry restores the exact same level');
  }
  for (const direction of route) vm.tap(direction);
  assert.equal(vm.state.outcome, 1);
  assert.equal(vm.state.moves, levels[number - 1].minMoves);
  assert.equal(vm.sokobanCompleted, number);
  assert.equal(data.getModeScore('sokoban', 'normal'), 85);
  assert.equal(data.getGameById('sokoban').highScore, 85);
  data.flushNow();
  const reopened = launch(Object.fromEntries(app.values));
  assert.equal(reopened.vm.sokobanLevel, Math.min(number + 1, levels.length));
  assert.equal(reopened.vm.sokobanCompleted, number);
  reopened.vm.dispose();
}

vm.selectSokobanLevel(1);
for (const direction of shortestRoute(levels[0].rows)) vm.tap(direction);
assert.equal(vm.sokobanCompleted, levels.length, 'replaying a cleared level keeps all unlocks');
vm.selectSokobanLevel(0);
assert.equal(vm.state.sokobanLevel, undefined);
const legacySnapshot = vm.exportContinuation();
const randomReplay = launch(Object.fromEntries(app.values));
assert.equal(randomReplay.vm.sokobanLevel, 0);
assert.ok(randomReplay.vm.importContinuation(legacySnapshot));
for (const direction of vm.state.target.slice()) vm.tap(direction);
assert.equal(vm.state.outcome, 1);
assert.ok(data.getModeScore('sokoban', 'normal') > 85, 'random boards still record normal scores');
assert.equal(vm.sokobanCompleted, levels.length);

const { ExpansionState, ExpansionPiece } = app.load('entry/src/main/ets/model/game/ExpansionState.ets');
function oldCampaign(number, terrain, player, boxes, moves, outcome) {
  const state = new ExpansionState();
  state.id = 'sokoban'; state.sokobanLevel = number; state.cols = state.rows = 7;
  state.board = Array.from(terrain, Number); state.cursor = player; state.moves = moves;
  state.goal = boxes.length; state.outcome = outcome;
  state.pieces = boxes.map(([cell, color], id) => {
    const piece = new ExpansionPiece();
    piece.id = id; piece.kind = 5; piece.x = cell % 7; piece.y = Math.floor(cell / 7); piece.color = color;
    return piece;
  });
  return JSON.stringify({ version: 1, state, recorded: outcome === 1, paused: false });
}
const previousFirst = '1111111111111111000111000201110001111111111111111';
const previousLast = '1111111101701110120011000001100001111030111111111';
const transferred = launch();
const currentModel = new (app.rules('Expansion').ExpansionModel)();
const firstInFlight = oldCampaign(1, previousFirst, 16, [[24, 0]], 1, 0);
assert.ok(transferred.vm.importContinuation(firstInFlight));
currentModel.startSokobanLevel(1);
assert.deepEqual(JSON.parse(JSON.stringify(transferred.vm.state)), JSON.parse(JSON.stringify(currentModel.state)));
const damaged = JSON.parse(firstInFlight);
damaged.state.board[0] = 0;
assert.equal(transferred.vm.importContinuation(JSON.stringify(damaged)), false);
assert.deepEqual(JSON.parse(JSON.stringify(transferred.vm.state)), JSON.parse(JSON.stringify(currentModel.state)));
assert.ok(transferred.vm.importContinuation(oldCampaign(1, previousFirst, 24, [[25, 0]], 1, 1)));
assert.equal(transferred.vm.sokobanLevel, 2);
assert.equal(transferred.vm.sokobanCompleted, 1);
assert.equal(transferred.vm.state.moves, 0);
assert.ok(transferred.vm.importContinuation(oldCampaign(12, previousLast, 23, [[38, 1], [17, 0]], 44, 1)));
assert.equal(transferred.vm.sokobanLevel, 12);
assert.equal(transferred.vm.sokobanCompleted, 12);
assert.equal(transferred.vm.state.moves, 0);
assert.equal(transferred.app.data().getModeScore('sokoban', 'campaign'), 12);
assert.ok(transferred.vm.importContinuation(firstInFlight));
assert.equal(transferred.vm.sokobanCompleted, 12, 'an old replay preserves a higher local unlock');
transferred.vm.selectSokobanLevel(0);
transferred.vm.tap(transferred.vm.state.target[0]);
const randomInFlight = transferred.vm.exportContinuation();
assert.ok(randomReplay.vm.importContinuation(randomInFlight));
assert.deepEqual(randomReplay.vm.state, transferred.vm.state, 'random snapshots resume from their original position');
transferred.vm.dispose();
vm.dispose();
randomReplay.vm.dispose();
console.log(`${levels.length + 1}/${levels.length + 1} Sokoban campaign checks passed; previous campaign and random continuations passed`);
