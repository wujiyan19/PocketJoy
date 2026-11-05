/* Reproduce confirmed review defects against the real models and controlled native boundaries. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { fixture } = require('./test-performance.cjs');
const tests = [];
const test = (name, run) => tests.push({ name, run });

test('seeded random agrees with exact 31-bit arithmetic, stays in range, and escapes reported short cycles', () => {
  const f = fixture();
  for (const seed of [0, 1, 3, 298, 58381, 2147483647]) {
    const random = f.rng(seed), seen = new Set(); let exact = BigInt(seed);
    for (let draw = 0; draw < 4096; draw++) {
      exact = (exact * 1103515245n + 12345n) % 2147483648n;
      const value = random.next();
      assert(value >= 0 && value < 1);
      assert.equal(value, Number(exact) / 2147483648);
      assert(!seen.has(value), `short cycle: ${seed}/${draw}`); seen.add(value);
    }
  }
});

test('every non-square piece rotates on an empty floor without mutating input or crossing board edges', () => {
  const f = fixture(), { TetrisRules, ActivePiece, SHAPES } = f.rules('Tetris');
  const rules = new TetrisRules(10, 20), board = rules.emptyBoard();
  SHAPES.forEach((shapes, idx) => shapes.forEach((shape, rot) => {
    if (shapes.length === 1) return;
    const piece = new ActivePiece(idx, rot, 3, 20 - shape.length), before = JSON.stringify(piece);
    const next = rules.rotated(board, piece);
    assert.equal(next.rot, (rot + 1) % shapes.length);
    assert(rules.canPlace(board, next, 0, 0)); assert.equal(JSON.stringify(piece), before);
  }));
  const edge = rules.rotated(board, new ActivePiece(0, 1, 9, 5));
  assert.equal(edge.rot, 0); assert.equal(edge.x, 6);
});

test('floor kicks cannot rotate through an enclosing stack', () => {
  const f = fixture(), { TetrisRules, ActivePiece, SHAPES } = f.rules('Tetris');
  const rules = new TetrisRules(10, 20), board = rules.emptyBoard().map(row => row.fill(1));
  const piece = new ActivePiece(2, 0, 3, 18);
  SHAPES[2][0].forEach((row, r) => row.forEach((value, c) => { if (value) board[18 + r][3 + c] = 0; }));
  assert(rules.canPlace(board, piece, 0, 0));
  assert.equal(rules.rotated(board, piece), piece);
});

test('captured v1 toy and screw saves restore without changing geometry, progress or generator version', () => {
  const saves = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures/review-legacy-toy-saves.json'), 'utf8')).saves;
  for (const state of saves) {
    const f = fixture(), vm = f.vm('ExpansionViewModel'); vm.init(state.id);
    assert(vm.importContinuation(JSON.stringify({ version: 1, state, recorded: false, paused: false })));
    assert.deepEqual(JSON.parse(vm.exportContinuation()).state, state);
    vm.dispose();
  }
});

test('new toys use generator v2 and reject a changed seed instead of rerolling the saved deal', () => {
  const f = fixture(), { ExpansionModel } = f.rules('Expansion');
  for (const id of ['blackhole', 'drift']) {
    const model = new ExpansionModel(f.rng(83)); model.start(id, 1);
    assert.equal(model.state.data[id === 'blackhole' ? 0 : 3], 2);
    assert(model.valid(model.state));
    const bad = JSON.parse(JSON.stringify(model.state)); bad.data[id === 'blackhole' ? 1 : 4]++;
    assert.equal(model.valid(bad), false);
  }
});

test('a full bus tray produces a loss and undo restores playable progress', () => {
  const f = fixture(), { ExpansionModel } = f.rules('Expansion');
  const { SeededRandom } = f.load('entry/src/main/ets/model/game/RandomSource.ets');
  const model = new ExpansionModel(new SeededRandom(1, true)); model.start('buscolor', 1);
  model.tap(0); model.tap(0); const before = JSON.stringify(model.state); model.tap(0);
  assert.equal(model.state.outcome, 2); assert(model.valid(model.state)); assert(model.canUndo());
  model.undo(); assert.equal(JSON.stringify(model.state), before);
  assert.equal(model.state.outcome, 0);
});

test('bus witness routes still win after deadlock detection', () => {
  const f = fixture(), { ExpansionModel } = f.rules('Expansion');
  for (const level of [0, 1, 2]) for (let seed = 1; seed <= 50; seed++) {
    const model = new ExpansionModel(f.rng(seed)); model.start('buscolor', level);
    const route = model.state.data.slice(3);
    for (const lane of route) { model.tap(lane); assert(model.valid(model.state)); }
    assert.equal(model.state.outcome, 1, `${level}/${seed}`);
  }
});

test('bus view model reopens scoring after undoing a terminal move', () => {
  const f = fixture(), vm = f.vm('ExpansionViewModel'); f.data().init({}); vm.init('buscolor');
  const { SeededRandom } = f.load('entry/src/main/ets/model/game/RandomSource.ets');
  vm.model.sorting.random = new SeededRandom(1, true); vm.startGame();
  const route = vm.state.data.slice(3);
  vm.tap(0); vm.tap(0); vm.tap(0); assert(vm.isFinished); assert(vm.canUndo);
  vm.undo(); vm.undo(); vm.undo(); assert.equal(vm.isFinished, false);
  for (const lane of route) vm.tap(lane);
  assert.equal(vm.state.outcome, 1); assert.equal(vm.modeHighScore, vm.state.score); vm.dispose();
});

test('additional brick rows never score more than a row above, while opening-level scores remain stable', () => {
  const f = fixture(), { BrickBreakerRules } = f.rules('BrickBreaker'), rules = new BrickBreakerRules();
  assert.deepEqual(rules.generateLayout(1).filter(b => b.col === 0).map(b => b.scoreValue), [50, 40, 30, 20, 10]);
  for (const level of [3, 5, 7, 30]) {
    const scores = rules.generateLayout(level).filter(b => b.col === 0).map(b => b.scoreValue);
    assert(scores.every((value, i) => value > 0 && (i === 0 || value <= scores[i - 1])));
  }
});

test('a failed save-key read cannot disable unrelated scores or replace the unread saved game', () => {
  const f = fixture({ savedGame2048: 'original-save', highScores: '{"snake":50}' });
  const get = f.store.getSync; f.store.getSync = function (key, fallback) {
    if (key === 'savedGame2048') throw Error('injected read failure'); return get.call(this, key, fallback);
  };
  const data = f.data(); data.init({}); data.updateHighScore('snake', 120); data.setSavedGame('sudoku', 'new-sudoku'); data.flushNow();
  assert.equal(JSON.parse(f.values.get('highScores')).snake, 120);
  assert.equal(f.values.get('savedGame2048'), 'original-save'); assert.equal(f.values.get('savedGameSudoku'), 'new-sudoku');
});

test('unread score maps survive unrelated writes; an explicit clear can replace them', () => {
  const f = fixture({ highScores: '{"snake":999,"tictactoe":42}', settings: '{"soundEnabled":false}' });
  const get = f.store.getSync; f.store.getSync = function (key, fallback) {
    if (key === 'highScores') throw Error('injected read failure'); return get.call(this, key, fallback);
  };
  const data = f.data(); data.init({}); data.setSetting('hapticsEnabled', false);
  assert.equal(f.values.get('highScores'), '{"snake":999,"tictactoe":42}');
  data.clearPlayData(); assert.equal(JSON.parse(f.values.get('highScores')).snake, 0);
  assert.equal(JSON.parse(f.values.get('settings')).soundEnabled, false);
});

test('clear statistics write failure stays inside persistence and the next flush completes the clear', () => {
  const f = fixture({ modeRecordsV1: '{"snake|normal":100}', highScores: '{"snake":50}' }), data = f.data(); data.init({});
  const put = f.store.putSync; let fail = true;
  f.store.putSync = function (key, value) { if (fail && key === 'modeRecordsV1') throw Error('injected write failure'); put.call(this, key, value); };
  assert.doesNotThrow(() => data.clearPlayData()); fail = false; data.flushNow();
  assert.deepEqual(JSON.parse(f.values.get('modeRecordsV1')), {});
  const restored = fixture(Object.fromEntries(f.values)); restored.data().init({});
  assert.equal(restored.data().getGameById('snake').highScore, 0);
});

test('window avoid-area updates keep the same shared observed instance and convert pixels to vp', () => {
  const f = fixture(); f.native['@kit.ArkUI'].window = { AvoidAreaType: { TYPE_NAVIGATION_INDICATOR: 1 } };
  f.native['@kit.ArkUI'].display.getDefaultDisplaySync = () => ({ densityPixels: 2 });
  const { SafeAreaInsets } = f.load('entry/src/main/ets/common/SafeAreaInsets.ets'); const state = SafeAreaInsets.state;
  for (const pixels of [24, 0, 40]) {
    SafeAreaInsets.updateFromWindow({ getWindowAvoidArea: () => ({ bottomRect: { height: pixels } }) });
    assert.equal(SafeAreaInsets.state, state); assert.equal(state.bottom, pixels / 2);
  }
});

let failed = 0;
for (const entry of tests) {
  try { entry.run(); } catch (error) { failed++; console.error('FAIL ' + entry.name + '\n' + error.stack); }
}
console.log(`${tests.length - failed}/${tests.length} review fix checks passed.`);
process.exitCode = failed ? 1 : 0;
