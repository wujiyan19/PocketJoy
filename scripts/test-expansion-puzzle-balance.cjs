const assert = require('node:assert/strict');
const { fixture } = require('./test-performance.cjs');

const f = fixture();
const { ExpansionModel } = f.rules('Expansion');
const { isDangerousFish } = f.load('entry/src/main/ets/model/game/ExpansionAdventure.ets');
let passed = 0;
function test(name, run) {
  run();
  passed++;
  console.log('PASS ' + name);
}

for (const level of [0, 1, 2]) {
  test(`fish retain prey and predators at the start and just before victory, level ${level}`, () => {
    const model = new ExpansionModel(f.rng(12));
    model.start('fisheat', level);
    const state = model.state;
    const player = state.pieces[0];
    for (const bites of [0, state.goal - 1]) {
      player.r = 14 + bites * 0.7;
      state.moves = bites;
      // Swim the old school off the left edge so the normal frame replaces it.
      for (const fish of state.pieces.slice(1)) fish.x = -55;
      model.aim(player.x, player.y);
      model.step(0.008);
      const fish = state.pieces.slice(1);
      assert.equal(fish.filter(item => isDangerousFish(player.r, item.r)).length, 2 + level);
      assert(fish.some(item => item.r < player.r));
      assert(model.valid(state));
    }
  });
}

function playableGroups(model, state) {
  const visited = new Set();
  const groups = [];
  for (let i = 0; i < state.board.length; i++) {
    if (!state.board[i] || visited.has(i)) continue;
    const group = model.matching.group(state, i);
    for (const cell of group) visited.add(cell);
    if (group.length >= 2) groups.push(group);
  }
  return groups;
}

for (const level of [0, 1, 2]) {
  test(`group clear rewards planning on the same 100 deals, level ${level}`, () => {
    const wins = [];
    for (const planAhead of [false, true]) {
      let count = 0;
      for (let seed = 40001; seed <= 40100; seed++) {
        const model = new ExpansionModel(f.rng(seed));
        model.start('groupclear', level);
        const state = model.state;
        while (!state.outcome) {
          const groups = playableGroups(model, state);
          let chosen = groups[0];
          if (planAhead) {
            let best = -1;
            for (const group of groups) {
              const trial = { ...state, board: state.board.slice() };
              model.matching.tap(trial, group[0]);
              const next = playableGroups(model, trial);
              const points = group.length ** 2 + Math.max(0, ...next.map(other => other.length ** 2));
              if (points > best) { best = points; chosen = group; }
            }
          }
          model.tap(chosen[0]);
        }
        if (state.outcome === 1) count++;
      }
      wins.push(count);
    }
    assert(wins[0] < 80 && wins[1] >= 55 && wins[1] - wins[0] >= 20, String(wins));
    console.log(`  first legal group ${wins[0]}/100, one move ahead ${wins[1]}/100`);
  });
}

test('a saved group-clear game continues with its original target', () => {
  for (const level of [0, 1, 2]) {
    const model = new ExpansionModel(f.rng(12));
    model.start('groupclear', level);
    const legacyGoal = 300 + 150 * level;
    model.state.goal = legacyGoal;
    const vm = f.vm('ExpansionViewModel');
    vm.init('groupclear');
    assert(vm.importContinuation(JSON.stringify({ version: 1, state: model.state, paused: false, recorded: false })));
    assert.equal(vm.state.goal, legacyGoal);
    vm.startGame();
    assert.notEqual(vm.state.goal, legacyGoal);
    vm.dispose();
  }
});

for (const sample of [
  { id: 'watersort', seed: 18, level: 2, pairs: [[5,2], [1,4], [0,5]] },
  { id: 'mahjongsolitaire', seed: 31, level: 1, pairs: [[12,31], [6,24], [18,25], [19,30], [0,20], [1,11],
    [17,28], [2,7], [3,27], [5,21], [23,26], [13,16], [15,22], [4,8], [9,10]] }
]) {
  test(`${sample.id} explains a reachable dead end and offers recovery after a continuation`, () => {
    const model = new ExpansionModel(f.rng(sample.seed));
    model.start(sample.id, sample.level);
    const vm = f.vm('ExpansionViewModel');
    vm.init(sample.id);
    assert(vm.importContinuation(JSON.stringify({ version: 1, state: model.state, paused: false, recorded: false })));
    for (const [from, to] of sample.pairs) { vm.tap(from); vm.tap(to); }
    assert(vm.puzzleStuck && vm.canUndo);
    if (sample.id === 'mahjongsolitaire') {
      vm.action();
      assert(vm.puzzleStuck);
    }
    const payload = vm.exportContinuation();
    vm.undo();
    assert(!vm.puzzleStuck);
    assert(vm.importContinuation(payload));
    assert(vm.puzzleStuck && !vm.canUndo);
    vm.tap(sample.id === 'watersort' ? 0 : 29);
    assert(vm.puzzleStuck && !vm.canUndo);
    vm.startGame();
    assert(!vm.puzzleStuck && !vm.canUndo);
    assert.equal(vm.state.outcome, 0);
    vm.dispose();
  });
}
console.log(`${passed}/${passed} fish, group-clear and dead-end checks passed.`);
