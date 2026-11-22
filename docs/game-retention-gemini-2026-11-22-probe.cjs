'use strict';

// Run with Node from the LittleGames project root. All inputs reach the real
// game models through their public controls. No saves or project files are written.
const path = require('node:path');
const { fixture } = require(path.resolve('scripts/test-performance.cjs'));
const fixtureData = fixture();
const { ExpansionModel } = fixtureData.rules('Expansion');
const modelDir = 'entry/src/main/ets/model/game/';
const { CollectionModel } = fixtureData.load(modelDir + 'CollectionModel.ets');
const { SeededRandom } = fixtureData.load(modelDir + 'RandomSource.ets');

const gamesPerDifficulty = 100;
const difficulties = ['easy', 'normal', 'hard'];
const fixedStep = 0.02;

function newExpansion(id, level, seed) {
  const model = new ExpansionModel(fixtureData.rng(seed));
  model.start(id, level);
  return model;
}

function floodProbe(level) {
  let wins = 0;
  const budgets = [];
  for (let index = 0; index < gamesPerDifficulty; index++) {
    const model = new CollectionModel(new SeededRandom(30001 + index));
    const choosing = new SeededRandom(61001 + index);
    model.start('flood', level);
    const state = model.state;
    budgets.push(state.answer);
    while (!state.outcome) {
      const choices = state.choices.filter(color => color !== state.board[0]);
      model.choose(choices[Math.floor(choosing.next() * choices.length)]);
    }
    if (state.outcome === 1) wins++;
  }
  return { wins, minBudget: Math.min(...budgets), maxBudget: Math.max(...budgets) };
}

// The UI shows all segments in each column, with an outline on the top cell.
// Inspect only those visible segments. Never read the generated solution.
function yarnTops(state) {
  const tops = [];
  for (let column = 0; column < state.cols; column++) {
    const stack = state.board.slice(column * 8, column * 8 + 8).filter(Boolean);
    if (!stack.length) continue;
    const color = stack[stack.length - 1];
    let size = 0;
    for (let i = stack.length - 1; i >= 0 && stack[i] === color; i--) size++;
    tops.push({ column, color, size });
  }
  return tops;
}

function yarnProbe(level) {
  let singleReelWins = 0;
  let stranded = 0;
  let undoAvailable = 0;
  for (let index = 0; index < gamesPerDifficulty; index++) {
    const seed = 40001 + index;
    const single = newExpansion('yarn', level, seed);
    while (!single.state.outcome && single.state.moves < 100) {
      const state = single.state;
      const tops = yarnTops(state);
      const visible = new Array(state.cols + 1).fill(0);
      for (const top of tops) visible[top.color] += top.size;
      const color = state.tray[0] || visible.indexOf(8);
      const next = tops.find(top => top.color === color);
      if (!next) break;
      single.tap(next.column); // Keep the default first reel throughout.
    }
    if (single.state.outcome === 1) singleReelWins++;

    const randomPlay = newExpansion('yarn', level, seed);
    const choice = fixtureData.rng(seed + 3456);
    while (!randomPlay.state.outcome && randomPlay.state.moves < 100) {
      const state = randomPlay.state;
      const legal = [];
      for (const top of yarnTops(state)) {
        for (let reel = 0; reel < 3; reel++) {
          if (!state.tray[reel * 2] || state.tray[reel * 2] === top.color) {
            legal.push({ column: top.column, reel });
          }
        }
      }
      if (!legal.length) {
        stranded++;
        if (randomPlay.canUndo()) undoAvailable++;
        break;
      }
      const move = legal[Math.floor(choice.next() * legal.length)];
      randomPlay.choose(move.reel);
      randomPlay.tap(move.column);
    }
  }
  return { singleReelWins, randomLegalPlayStranded: stranded, undoAvailable };
}

function arcadeProbe(id, level, policy) {
  let wins = 0;
  for (let index = 0; index < gamesPerDifficulty; index++) {
    const model = newExpansion(id, level, 40001 + index);
    model.activate();
    for (let step = 0; step < 6250 && !model.state.outcome; step++) {
      if (step % 50 === 0) { // Once per simulated second.
        if (policy === 'build') {
          for (let slot = 0; slot < 6; slot++) model.tap(slot);
        }
        if (policy === 'cookAlways' || policy === 'cookIfLow') {
          for (let dish = 0; dish < 3; dish++) {
            if (policy === 'cookAlways' || model.state.board[dish] < 2) model.tap(dish);
          }
          const customers = model.state.pieces.filter(piece => piece.kind === 19);
          for (const customer of customers) model.tap(100 + customer.id);
        }
      }
      model.step(fixedStep);
    }
    if (model.state.outcome === 1) wins++;
  }
  return wins;
}

const firingPatterns = {
  straightUp: [[180, 50]],
  diagonalLeft: [[30, 170]],
  horizontalLeft: [[20, 400]],
  shallowLeft: [[30, 365]],
  alternateSides: [[30, 365], [330, 365]],
  sweepThree: [[60, 70], [180, 70], [300, 70]],
  sweepFive: [[35, 95], [105, 95], [180, 95], [255, 95], [325, 95]],
  targetFirstEnemy: null
};

function fortressProbe(level, intervalSteps, pattern) {
  let wins = 0;
  let fullHealthWins = 0;
  let healthSum = 0;
  for (let index = 0; index < gamesPerDifficulty; index++) {
    const model = newExpansion('fortress', level, 40001 + index);
    model.activate();
    let shot = 0;
    for (let step = 0; step < 5000 && !model.state.outcome; step++) {
      if (step % intervalSteps === 0) {
        model.tap(0); // Always try to buy a firepower upgrade at the same cadence.
        if (pattern) {
          const point = pattern[shot++ % pattern.length];
          model.aim(point[0], point[1]);
        } else {
          const enemy = model.state.pieces.find(piece => piece.kind === 33 && piece.alive);
          if (enemy) model.aim(enemy.x, enemy.y);
        }
      }
      model.step(fixedStep);
    }
    const health = model.state.data[0];
    if (model.state.outcome === 1) {
      wins++;
      if (health === 100) fullHealthWins++;
    }
    healthSum += health;
  }
  return { wins, fullHealthWins, meanFinalHealth: healthSum / gamesPerDifficulty };
}

const result = {
  sample: {
    gamesPerDifficulty,
    difficultyOrder: difficulties,
    gameSeeds: '40001–40100',
    floodBoardSeeds: '30001–30100',
    floodActionSeeds: '61001–61100',
    yarnRandomActions: 'game seed + 3456',
    stepSeconds: fixedStep
  }
};
for (const [level, difficulty] of difficulties.entries()) {
  const fortress = {};
  for (const interval of [16, 25, 50]) {
    const names = interval === 16 ? Object.keys(firingPatterns) : ['sweepFive', 'targetFirstEnemy'];
    const data = {};
    for (const name of names) data[name] = fortressProbe(level, interval, firingPatterns[name]);
    fortress[(interval * fixedStep).toString() + ' seconds'] = data;
  }
  result[difficulty] = {
    flood: floodProbe(level),
    yarn: yarnProbe(level),
    restaurant: {
      cookAllAndTapAllWins: arcadeProbe('restaurant', level, 'cookAlways'),
      cookWhenStockBelowTwoWins: arcadeProbe('restaurant', level, 'cookIfLow')
    },
    roomdefense: {
      tapSixSlotsWins: arcadeProbe('roomdefense', level, 'build'),
      noBuildWins: arcadeProbe('roomdefense', level, 'noBuild')
    },
    fortress
  };
}
console.log(JSON.stringify(result, null, 2));
