/* Read-only product-audit probes against the current working-tree ArkTS models.
 * Desktop fixture only: no device, human difficulty, retention or rendering claims.
 * Run: node docs/game-retention-audit-2026-10-27/probe.cjs
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const { fixture, Frames } = require(path.join(root, 'scripts/test-performance.cjs'));
const strings = Object.fromEntries(JSON.parse(fs.readFileSync(path.join(root,
  'entry/src/main/resources/base/element/string.json'), 'utf8')).string.map(x => [x.name, x.value]));
const f = fixture({}, key => strings[key.replace('app.string.', '')] || key);
const data = f.data(); data.init({});
const { CollectionModel, COLLECTION_IDS } = f.rules('Collection');
const { ExpansionModel, PLAYABLE_EXPANSION_IDS } = f.rules('Expansion');
const seeds = Array.from({ length: 30 }, (_, i) => i + 1);
const levels = [0, 1, 2];
const create = (id, level, seed = 1) => {
  const m = COLLECTION_IDS.includes(id) ? new CollectionModel(f.rng(seed)) : new ExpansionModel(f.rng(seed));
  m.start(id, level); return m;
};
const key = s => JSON.stringify(s, (k, v) => ['level', 'score'].includes(k) ? undefined : v);
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
const catalog = data.getAllGames().map(g => ({ id: g.id, name: g.name, category: g.category }));
const open = new Set(catalog.map(g => g.id));
const allModelIds = [...COLLECTION_IDS, ...PLAYABLE_EXPANSION_IDS];
const openings = allModelIds.map(id => {
  const samples = levels.map(level => {
    const states = seeds.map(seed => create(id, level, seed).state);
    const s = states[0];
    return { level, uniqueOpeningStates: new Set(states.map(key)).size,
      cols: s.cols, rows: s.rows ?? null, boardCells: s.board.length,
      pieceCount: s.pieces?.length ?? 0, goal: s.goal ?? null,
      firstOpening: s, firstOpeningHashWithoutLevelAndScore: digest(key(s)) };
  });
  return { id, available: open.has(id), samples,
    equalOpeningsAcrossDifficultiesForAll30Seeds: seeds.every(seed =>
      new Set(levels.map(level => key(create(id, level, seed).state))).size === 1) };
});
const results = {};
// All actions below use the same public model methods that the view model calls.
results.jumpFullCharge = ['easy', 'normal', 'hard'].map(difficulty => {
  const vm = f.vm('JumpJumpViewModel'); const frames = new Frames();
  vm.setFrameLoop(frames); vm.changeDifficulty(difficulty); vm.newGame();
  for (let jump = 0; jump < 100 && vm.status === 'playing'; jump++) {
    vm.beginCharge(); frames.tick(1500); vm.endCharge(); frames.tick(1500);
  }
  const result = { difficulty, score: vm.score, status: vm.status, attemptedJumps: 100 };
  vm.dispose(); return result;
});
results.slotpairSameColumn = levels.map(level => {
  let wins = 0; const scores = new Set();
  for (const seed of seeds) {
    const m = create('slotpair', level, seed);
    for (let i = 0; i < 100 && m.state.outcome === 0; i++) m.tap(0);
    if (m.state.outcome === 1) wins++;
    scores.add(m.state.score);
  }
  return { level, wins, trials: seeds.length, scores: [...scores] };
});
results.missingVisibleElimination = levels.map(level => {
  let wins = 0; const scores = new Set();
  for (const seed of seeds) {
    const m = create('missing', level, seed);
    for (let round = 0; round < 10 && m.state.outcome === 0; round++) {
      m.action(); // The remaining cards and all answer choices are now both visible.
      m.choose(m.state.choices.findIndex(value => !m.state.board.includes(value)));
    }
    if (m.state.outcome === 1) wins++;
    scores.add(m.state.score);
  }
  return { level, wins, trials: seeds.length, scores: [...scores],
    strategy: 'Use only the remaining visible cards and choices; never read or memorize the original target.' };
});
results.sand = levels.map(level => {
  let wins = 0; const scores = new Set(); const moves = [];
  for (const seed of seeds) {
    const m = create('sand', level, seed);
    for (let guard = 0; guard < 200 && m.state.outcome === 0; guard++) {
      const at = m.state.board.findIndex(v => v > 0);
      if (at < 0) break;
      m.choose(m.state.board[at] - 1); m.tap(at);
    }
    if (m.state.outcome === 1) wins++;
    scores.add(m.state.score); moves.push(m.state.moves);
  }
  return { level, wins, trials: seeds.length, scores: [...scores], moveRange: [Math.min(...moves), Math.max(...moves)] };
});
results.lineRescueSameClosedSquare = levels.map(level => {
  let wins = 0;
  for (const seed of seeds) {
    const m = create('linerescue', level, seed);
    [[130, 200], [230, 200], [230, 300], [130, 300], [130, 200]].forEach(p => m.aim(p[0], p[1]));
    m.activate();
    for (let i = 0; i < 700 && m.state.outcome === 0; i++) m.step(1 / 60);
    if (m.state.outcome === 1) wins++;
  }
  return { level, wins, trials: seeds.length };
});
results.pipes = levels.map(level => ({ level,
  uniqueSolvedTopologies: new Set(seeds.map(seed => JSON.stringify(create('pipes', level, seed).state.target))).size,
  uniqueScrambledBoards: new Set(seeds.map(seed => JSON.stringify(create('pipes', level, seed).state.board))).size }));
results.untangle = levels.map(level => ({ level,
  uniqueGraphs: new Set(seeds.map(seed => JSON.stringify(create('untangle', level, seed).state.board))).size,
  uniquePositions: new Set(seeds.map(seed => JSON.stringify(create('untangle', level, seed).state.pieces))).size }));
results.targetsum = levels.map(level => {
  const answers = []; const prompts = new Set();
  for (const seed of seeds) {
    const m = create('targetsum', level, seed);
    for (let round = 0; round < 10; round++) {
      answers.push(m.state.answer); prompts.add(m.state.prompt);
      m.choose(m.state.choices.indexOf(m.state.answer));
    }
  }
  return { level, answerRange: [Math.min(...answers), Math.max(...answers)],
    uniqueAnswers: new Set(answers).size, uniquePrompts: prompts.size, rounds: answers.length };
});
results.bowlingFixedThreeShots = levels.map(level => {
  const m = create('bowling', level);
  const shots = [];
  for (const target of [[180, 100], [140, 70], [220, 70]]) {
    if (m.state.outcome !== 0) break;
    m.aim(target[0], target[1]);
    for (let frame = 0; frame < 250 && m.state.phase === 1 && m.state.outcome === 0; frame++) m.step(1 / 60);
    shots.push({ cursor: m.state.cursor, outcome: m.state.outcome });
  }
  return { level, shots, score: m.state.score, outcome: m.state.outcome };
});
results.sameRulesTrace = ['fruitmerge', 'solitaire', 'spider', 'freecell', 'melody'].map(id => {
  const ms = levels.map(level => create(id, level, 19));
  for (let i = 0; i < 120; i++) {
    for (const m of ms) {
      if (id === 'fruitmerge') { if (i % 30 === 0) m.aim([75, 180, 285][Math.floor(i / 30) % 3], 50); m.step(1 / 60); }
      if (id === 'solitaire') m.tap(i % 3 === 0 ? 100 : i % 52);
      if (id === 'spider') m.tap(i % 20 === 0 ? 900 : i % 104);
      if (id === 'freecell') m.tap(i % 52);
      if (id === 'melody') { if (i === 0) m.activate(); m.step(1 / 60); }
    }
  }
  return { id, equalFinalStatesWithoutLevelAndScore: new Set(ms.map(m => key(m.state))).size === 1,
    steps: 120, note: 'Controlled traces support the source review; this is not exhaustive gameplay coverage.' };
});
const relativeFiles = [];
const walk = directory => {
  for (const entry of fs.readdirSync(path.join(root, directory), { withFileTypes: true })) {
    const rel = path.posix.join(directory, entry.name);
    if (entry.isDirectory()) walk(rel);
    else if (entry.name.endsWith('.ets') || entry.name.endsWith('.json')) relativeFiles.push(rel);
  }
};
walk('entry/src/main/ets');
relativeFiles.push('entry/src/main/resources/base/element/string.json', 'scripts/test-performance.cjs');
const report = { createdAt: new Date().toISOString(), auditDate: '2026-10-27',
  scope: 'Current working tree; desktop model probes; 30 fixed seeds per difficulty. Equal openings alone do not prove equal runtime rules.',
  head: cp.execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(),
  availableCount: catalog.length, retiredModelCount: allModelIds.filter(id => !open.has(id)).length,
  catalog, openings, probes: results,
  sourceHashes: Object.fromEntries(relativeFiles.sort().map(file => [file, digest(fs.readFileSync(path.join(root, file)))])) };
fs.writeFileSync(path.join(__dirname, 'model-probes.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ availableCount: catalog.length,
  equalOpenings: openings.filter(x => x.available && x.equalOpeningsAcrossDifficultiesForAll30Seeds).map(x => x.id),
  probes: results }, null, 2));
