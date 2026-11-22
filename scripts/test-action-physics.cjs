const assert = require('node:assert/strict');
const { fixture } = require('./test-performance.cjs');
const { paceHillClimb } = require('./retention-game-controls.cjs');

const app = fixture();
const { ExpansionModel } = app.rules('Expansion');
const { ExpansionPiece } = app.load('entry/src/main/ets/model/game/ExpansionState.ets');
const tests = [];
const test = (name, run) => tests.push({ name, run });

function start(id, level = 1, seed = 7919) {
  const model = new ExpansionModel(app.rng(seed));
  model.start(id, level);
  model.activate();
  return model;
}

test('grapple: releasing in mid-air gives no impulse until an anchor is attached', () => {
  for (let level = 0; level < 3; level++) {
    const model = start('grapple', level);
    for (let frame = 0; frame < 2000 && !model.state.outcome; frame++) {
      if (frame % 100 === 0) model.tap(1);
      model.step(0.008);
    }
    assert.equal(model.state.moves, 0);
    assert.equal(model.state.outcome, 2);

    const attached = start('grapple', level);
    attached.tap(0);
    assert.ok(attached.state.selected >= 0);
    attached.tap(1);
    assert.equal(attached.state.selected, -1);
    assert.equal(attached.state.moves, 1);
    attached.tap(1);
    assert.equal(attached.state.moves, 1);
  }
});

test('hill climb: holding the accelerator works on easy, upper courses reward speed control', () => {
  for (let level = 0; level < 3; level++) {
    for (let seed = 1; seed <= 30; seed++) {
      for (const controlled of [false, true]) {
        const model = start('hillclimb', level, seed * 7919);
        model.tap(0);
        for (let frame = 0; frame < 9000 && !model.state.outcome; frame++) {
          if (controlled) paceHillClimb(model, frame);
          model.step(0.008);
        }
        assert.equal(model.state.outcome, controlled || level === 0 ? 1 : 2, `${level}/${seed}/${controlled}`);
      }
    }
  }
});

test('hill climb: an earlier random course keeps its saved terrain and forgiving landing physics', () => {
  const model = start('hillclimb', 2);
  const previous = JSON.parse(JSON.stringify(model.state));
  previous.variant = 1;
  previous.board = [30, 120, 34, 23, 100, 210];
  previous.pieces[0].y = model.sports.terrain(previous.pieces[0].x, previous) - 16;
  assert.ok(model.valid(previous));
  model.restore(previous);
  model.tap(0);
  for (let frame = 0; frame < 9000 && !model.state.outcome; frame++) model.step(0.008);
  assert.deepEqual(model.state.board, previous.board);
  assert.equal(model.state.outcome, 1);
});

test('survival: the easy wave rewards repositioning and upgrades over waiting at spawn', () => {
  let idleWins = 0;
  let activeWins = 0;
  for (let seed = 1; seed <= 100; seed++) {
    for (const moving of [false, true]) {
      const model = start('survival', 0, seed * 7919);
      for (let frame = 0; frame < 12000 && !model.state.outcome; frame++) {
        if (moving && frame % 25 === 0) {
          const time = frame * 0.008;
          model.aim(180 + Math.sin(time * 0.6) * 145, 370 + Math.cos(time * 0.6) * 50);
          if (model.state.data[1] >= 20) {
            model.tap(model.state.data[0] < 2 ? 2 : model.state.board[0] < 2 ? 0 : 1);
          }
        }
        model.step(0.008);
      }
      assert.notEqual(model.state.outcome, 0);
      if (model.state.outcome === 1) {
        if (moving) activeWins++;
        else idleWins++;
      }
    }
  }
  assert.ok(idleWins <= 35 && activeWins >= 95, `idle ${idleWins}/100, active ${activeWins}/100`);
});

test('fruit slice: taps, touch jitter, and two separate taps are not a cut; slow swipes count', () => {
  const model = start('fruitslice');
  const fruit = new ExpansionPiece();
  fruit.kind = 30;
  fruit.x = 180;
  fruit.y = 230;
  fruit.r = 20;
  fruit.id = model.state.serial++;
  model.state.pieces.push(fruit);
  model.aim(180, 230);
  model.aim(181, 231);
  model.releaseControls();
  model.aim(183, 230);
  assert.equal(model.state.score, 0);
  for (let x = 184; x <= 189; x++) model.aim(x, 230);
  assert.equal(model.state.score, 50);
  assert.equal(model.state.moves, 1);
});

test('air hockey: a held or released stationary mallet does not retain an earlier stroke', () => {
  const rebound = (release, repeatPosition) => {
    const model = start('airhockey');
    model.aim(260, 420);
    if (repeatPosition) model.aim(260, 420);
    if (release) model.releaseControls();
    const ball = model.state.pieces[0];
    for (let i = 0; i < 250 && ball.vy === 170; i++) model.step(0.008);
    assert.ok(ball.vy < 0);
    return ball.vx;
  };
  assert.equal(rebound(false, false), rebound(true, true));
  assert.equal(rebound(true, false), rebound(true, true));
});

test('air hockey: a strike moving into the puck still gives a stronger rebound', () => {
  const model = start('airhockey');
  const ball = model.state.pieces[0];
  ball.x = 291; ball.y = 420; ball.vx = 0; ball.vy = 0;
  model.aim(260, 420);
  model.step(0.008);
  assert.ok(ball.vx > 400);
});

for (const { name, run } of tests) { run(); console.log('PASS ' + name); }
console.log(`${tests.length}/${tests.length} action physics checks passed`);
