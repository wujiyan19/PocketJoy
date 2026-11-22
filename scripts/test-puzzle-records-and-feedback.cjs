const assert = require('node:assert/strict');
const { fixture } = require('./test-performance.cjs');
const cases = [];
const test = (name, run) => cases.push({ name, run });

test('the three comparison relations are equally likely and agree with the displayed sums', () => {
  const f = fixture();
  const { CollectionModel } = f.rules('Collection');
  for (const level of [0, 1, 2]) {
    const model = new CollectionModel(f.rng(17041 + level));
    const counts = [0, 0, 0];
    for (let round = 0; round < 300; round++) {
      model.start('compare', level);
      for (let question = 0; question < 10; question++) {
        const state = model.state;
        const [a, b, c, d] = state.prompt.match(/\d+/g).map(Number);
        const expected = Math.sign(a + b - c - d);
        assert.equal(state.answer, expected);
        assert.deepEqual(state.choices, [-1, 0, 1]);
        counts[expected + 1]++;
        model.choose(expected + 1);
      }
      assert.equal(model.state.outcome, 1);
    }
    for (const count of counts) assert.ok(count >= 900 && count <= 1100, counts.join('/'));
  }
});

test('a full Sudoku board marks row, column and box conflicts and can be corrected', () => {
  const f = fixture(), vm = f.vm('SudokuViewModel', f.rng(211));
  vm.newGame();
  const solved = Array.from({ length: 81 }, (_, index) => {
    const row = Math.floor(index / 9);
    return (row * 3 + Math.floor(row / 3) + index % 9) % 9 + 1;
  });
  const state = JSON.parse(vm.exportContinuation());
  state.puzzle = solved.slice();
  state.puzzle[0] = 0;
  state.board = state.puzzle.slice();
  state.fixed = state.puzzle.map(number => number !== 0);
  assert.ok(vm.importContinuation(JSON.stringify(state)));
  vm.selectCell(0, 0);
  vm.setNumber(5);
  // These fixed 5s share the edited cell's row, column and box respectively.
  assert.deepEqual(vm.fullBoardConflicts.flatMap((bad, i) => bad ? [i] : []), [0, 4, 10, 36]);
  assert.equal(vm.status, 'playing');
  const restored = f.vm('SudokuViewModel');
  assert.ok(restored.importContinuation(vm.exportContinuation()));
  assert.deepEqual(restored.fullBoardConflicts, vm.fullBoardConflicts);
  vm.erase();
  assert.deepEqual(vm.fullBoardConflicts, []);
  vm.setNumber(1);
  assert.equal(vm.fullBoardConflicts.includes(true), false);
  assert.equal(vm.status, 'over');
});

test('memory records are the fewest attempts at the selected difficulty and old scores stay unclassified', () => {
  const f = fixture({ highScores: '{"memorycard":980}' });
  f.data().init({});
  const vm = f.vm('MemoryCardViewModel', f.rng(73));
  vm.changeDifficulty('easy');
  assert.equal(vm.getBestText(), '--');
  assert.equal(vm.unclassifiedScore, 980);
  const pairs = new Map();
  for (let i = 0; i < vm.cards.length; i++) {
    const pattern = vm.cardEmoji(i);
    if (!pairs.has(pattern)) pairs.set(pattern, []);
    pairs.get(pattern).push(i);
  }
  for (const pair of pairs.values()) {
    vm.flipCard(pair[0]);
    vm.flipCard(pair[1]);
    f.clock.advance(500);
  }
  assert.equal(vm.getBestText(), '6');
  vm.changeDifficulty('hard');
  assert.equal(vm.getBestText(), '--');
  f.data().flushNow();
  const reboot = fixture(Object.fromEntries(f.values));
  reboot.data().init({});
  const resumed = reboot.vm('MemoryCardViewModel', reboot.rng(105));
  resumed.changeDifficulty('easy');
  assert.equal(resumed.getBestText(), '6');
  assert.equal(resumed.unclassifiedScore, 980);
});

test('slide puzzle keeps an exact count per size, including counts beyond the old score floor', () => {
  const f = fixture(), vm = f.vm('SlidePuzzleViewModel', f.rng(44));
  f.data().init({});
  vm.changeDifficulty('hard');
  const almost = JSON.parse(vm.exportContinuation());
  almost.board = Array.from({ length: 25 }, (_, i) => i + 1);
  almost.board[23] = 0;
  almost.board[24] = 24;
  almost.steps = 1200;
  assert.ok(vm.importContinuation(JSON.stringify(almost)));
  vm.tapCell(4, 4);
  assert.equal(vm.getBestText(), '1201');
  assert.equal(vm.status, 'over');
  vm.changeDifficulty('easy');
  assert.equal(vm.getBestText(), '--');
  vm.changeDifficulty('hard');
  assert.equal(vm.getBestText(), '1201');
  assert.equal(vm.unclassifiedScore, 0);
});

for (const [name, id, field] of [
  ['SlidePuzzle', 'slidepuzzle', 'best'],
  ['MemoryCard', 'memorycard', 'bestScore']
]) {
  test(id + ' clearing records in settings cannot revive them when the current game resumes or finishes', () => {
    const f = fixture({ highScores: JSON.stringify({ [id]: 980 }),
      modeRecordsV1: JSON.stringify({ [id + ':easy:count']: 10 }) });
    const data = f.data(); data.init({});
    const vm = f.vm(name + 'ViewModel', f.rng(46));
    vm.changeDifficulty('easy');
    if (id === 'slidepuzzle') {
      const state = JSON.parse(vm.exportContinuation());
      state.board = [1,2,3,4,5,6,7,0,8]; state.steps = 29;
      assert(vm.importContinuation(JSON.stringify(state)));
    }
    assert.equal(vm.getBestText(), '10');
    vm.onAppHidden();
    data.clearPlayData();
    const hidden = JSON.parse(vm.exportContinuation());
    assert.deepEqual([hidden[field], hidden.difficultyBest, hidden.unclassifiedScore], [999, 0, 0]);
    vm.onAppShown();
    assert.equal(vm.getBestText(), '--');
    assert.equal(vm.unclassifiedScore, 0);
    if (id === 'slidepuzzle') {
      vm.tapCell(2, 2);
    } else {
      for (const emoji of new Set(vm.cards.map(card => card.emoji))) {
        for (let i = 0; i < vm.cards.length; i++) if (vm.cardEmoji(i) === emoji) vm.flipCard(i);
        f.clock.advance(500);
      }
    }
    const newBest = id === 'slidepuzzle' ? 30 : 6;
    assert.equal(vm.status, 'over');
    assert.equal(data.getBestCount(id, 'easy'), newBest);
    assert.equal(data.getUnclassifiedScore(id), 0);
    data.flushNow();
    const next = fixture(Object.fromEntries(f.values)); next.data().init({});
    assert.equal(next.data().getUnclassifiedScore(id), 0);
    assert.equal(next.data().getBestCount(id, 'easy'), newBest);
    // A distinct, subsequently accepted external session may supply its own archived result.
    const incoming = JSON.parse(vm.exportContinuation());
    incoming.unclassifiedScore = 979;
    assert(vm.importContinuation(JSON.stringify(incoming)));
    assert.equal(data.getUnclassifiedScore(id), 979);
  });

  test(id + ' sends the all-time minimum to old clients regardless of the active difficulty', () => {
    for (const [oldScore, easyCount, legacyBest] of [[0, 12, 12], [988, 12, 12], [995, 12, 5], [0, 1201, 999], [0, 0, 999]]) {
      const f = fixture({ highScores: JSON.stringify({ [id]: oldScore }) });
      const data = f.data(); data.init({});
      const vm = f.vm(name + 'ViewModel', f.rng(76));
      vm.changeDifficulty('easy');
      const result = JSON.parse(vm.exportContinuation());
      result.difficultyBest = easyCount;
      result.unclassifiedScore = oldScore;
      assert(vm.importContinuation(JSON.stringify(result)));
      vm.changeDifficulty('hard');
      const outgoing = JSON.parse(vm.exportContinuation());
      assert.equal(outgoing[field], legacyBest);
      assert.equal(outgoing.difficultyBest, 0);
      assert.equal(outgoing.unclassifiedScore, oldScore);
    }
  });

  test(id + ' keeps unscoped old continuation data separate and merges a new continuation into its own level', () => {
    const original = fixture(), target = fixture();
    original.data().init({});
    target.data().init({});
    const source = original.vm(name + 'ViewModel', original.rng(93));
    const destination = target.vm(name + 'ViewModel', target.rng(88));
    source.changeDifficulty('hard');
    const old = JSON.parse(source.exportContinuation());
    delete old.difficultyBest;
    delete old.unclassifiedScore;
    old[field] = 17;
    assert.ok(destination.importContinuation(JSON.stringify(old)));
    assert.equal(destination.difficulty, 'hard');
    assert.equal(destination.getBestText(), '--');
    assert.equal(destination.unclassifiedScore, 983);

    original.data().recordBestCount(id, 'easy', 12, 0);
    source.changeDifficulty('easy');
    assert.ok(destination.importContinuation(source.exportContinuation()));
    assert.equal(destination.getBestText(), '12');
    assert.equal(destination.unclassifiedScore, 983);
    assert.equal(target.data().getBestCount(id, 'hard'), 0);
  });
}

test('reaction keeps one lifetime best under every default difficulty, including old score-only records', () => {
  const f = fixture({ highScores: '{"reaction":1650}', modeRecordsV1: JSON.stringify({
    'reaction:easy:time': 430, 'reaction:hard:score': 1720, 'reaction:normal:time': 300
  }) });
  const data = f.data();
  data.init({});
  const vm = f.vm('CollectionViewModel');
  vm.init('reaction');
  vm.startGame();
  assert.equal(vm.reactionBestMs, 280);
  vm.tap(0);
  f.clock.advance(vm.state.signalAt - 100000 + 250);
  vm.tap(0);
  assert.equal(vm.reactionBestMs, 250);
  assert.equal(data.getModeTime('reaction', 'standard'), 250);
  assert.equal(data.getModeTime('reaction', 'normal'), 300);
  data.setTextSetting('defaultDifficulty', 'hard');
  const next = f.vm('CollectionViewModel');
  next.init('reaction');
  next.startGame();
  assert.equal(next.reactionBestMs, 250);
});

let passed = 0;
for (const entry of cases) {
  try {
    entry.run();
    passed++;
  } catch (error) {
    console.error('FAIL ' + entry.name, error);
  }
}
console.log(passed + '/' + cases.length + ' puzzle and reaction checks passed.');
process.exitCode = passed === cases.length ? 0 : 1;
