const assert = require('node:assert/strict');
const { fixture } = require('./test-performance.cjs');
const tests = [];
const test = (name, fn) => tests.push({name, fn});
test('moves and selection update retained pieces, including the new hit coordinates', () => {
  const f=fixture(),vm = f.vm('KlotskiViewModel',f.rng(3)); vm.startGame();
  const rules=new(f.rules('Klotski').KlotskiRules)(4,5),blocks=JSON.parse(vm.exportContinuation()).blocks;
  const move=blocks.flatMap(p=>[[0,-1],[1,0],[0,1],[-1,0]].map(([dx,dy])=>({p,dx,dy})))
    .find(({p,dx,dy})=>rules.canMove(blocks,rules.buildGrid(blocks),p.id,dx,dy));
  assert(move);const soldier=vm.piecesForView().find(p=>p.id===move.p.id),x=soldier.x,y=soldier.y;
  vm.selectBlockAt(y,x); assert.equal(soldier.selected, true);
  vm.moveBlock(move.dx,move.dy); assert.equal(soldier.x,x+move.dx); assert.equal(soldier.y,y+move.dy);
  assert.equal(vm.stepCount, 1);
  vm.selectBlockAt(soldier.y, soldier.x); assert.equal(soldier.selected, false);
  vm.selectBlockAt(soldier.y, soldier.x); vm.moveBlock(-move.dx,-move.dy);
  assert.equal(soldier.x,x);assert.equal(soldier.y,y);assert.equal(vm.stepCount,2);
  vm.moveBlock(2,0);assert.equal(soldier.x,x);assert.equal(vm.stepCount,2);
  assert.equal(vm.piecesForView().find(p => p.id === soldier.id), soldier);
});
test('a new deal updates retained positions and clears selection', () => {
  const f=fixture(),vm = f.vm('KlotskiViewModel',f.rng(7)); vm.startGame();
  const soldier=vm.piecesForView()[0];vm.selectBlockAt(soldier.y,soldier.x);vm.startGame();
  const original=JSON.parse(vm.exportContinuation()).blocks.find(p=>p.id===soldier.id);
  assert.equal(soldier.x,original.x);assert.equal(soldier.y,original.y);
  assert.equal(soldier.selected, false); assert.equal(vm.stepCount, 0);
});
test('all difficulties and continuation restore expose current pieces', () => {
  for (const difficulty of ['easy', 'normal', 'hard']) {
    const vm = fixture().vm('KlotskiViewModel'); vm.changeDifficulty(difficulty); vm.startGame();
    const p = vm.piecesForView()[0]; vm.selectBlockAt(p.y, p.x);
    const payload = vm.exportContinuation(); const restored = fixture().vm('KlotskiViewModel');
    assert.equal(restored.importContinuation(payload), true);
    assert.deepEqual(JSON.parse(JSON.stringify(restored.piecesForView())), JSON.parse(JSON.stringify(vm.piecesForView())));
  }
});
let failed = 0;
for (const {name, fn} of tests) { try { fn(); } catch (e) { failed++; console.error(name, e); } }
console.log(`${tests.length - failed}/${tests.length} Klotski UI-state regressions passed`);
process.exitCode = failed ? 1 : 0;
