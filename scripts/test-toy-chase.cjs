/* Independent desktop controls and asset contracts. Native rendering is checked separately. */
const assert=require('node:assert/strict');
const {fixture}=require('./test-performance.cjs');
const f=fixture(),{ExpansionModel}=f.rules('Expansion');
const {DriftLevels,BlackholeLevels}=f.load('entry/src/main/ets/model/game/ToyLevelRules.ets');
const create=(id,level=1,seed=19)=>{const m=new ExpansionModel(f.rng(seed));m.start(id,level);return m;};
let count=0,rounds=0;const stats={blackholeMaxSeconds:0,driftMaxError:[0,0,0],rounds:0};
const test=(name,fn)=>{fn();count++;console.log('PASS '+name);};
function center(s,t){
  if(s.board.length===0)return 180+Math.sin(t*.65)*90;
  const i=Math.min(s.board.length-2,Math.floor(Math.max(0,t)/4)),u=Math.min(1,(Math.max(0,t)-i*4)/4);
  return s.board[i]+(s.board[i+1]-s.board[i])*u*u*(3-2*u);
}
function run(m,control,period,limit){
  let next=0;for(let i=0;i<limit/.008&&!m.state.outcome;i++){
    if(m.state.time>=next){control(m);next+=period;}m.step(.008);
  }assert(m.valid(m.state),'valid completed state');
}
function blackControl(m){
  const p=m.state.pieces[0],items=m.state.pieces.slice(1).filter(q=>q.r<p.r*.9);
  items.sort((a,b)=>Math.hypot(a.x-p.x,a.y-p.y)-Math.hypot(b.x-p.x,b.y-p.y));
  if(items.length)m.aim(items[0].x,items[0].y);
}
function driftControl(m){const p=m.state.pieces[0],c=center(m.state,m.state.time);
  if((p.x>c+10&&p.vx>0)||(p.x<c-10&&p.vx<0))m.tap(0);
}
test('start buttons alone activate both games; the ready board never advances',()=>{
  for(const id of ['blackhole','drift']){const m=create(id);m.step(.008);assert.equal(m.state.time,0);
    m.activate();assert.equal(m.state.phase,1);m.step(.008);assert(m.state.time>0);assert(m.valid(m.state));}
});
for(const id of ['blackhole','drift'])for(const level of [0,1,2])test(`${id}/${level}: 1000 randomized rounds win with sampled controls`,()=>{
  const layouts=new Set();
  for(let seed=1;seed<=1000;seed++){
    const m=create(id,level,seed);assert(m.valid(m.state));
    layouts.add(JSON.stringify(id==='drift'?m.state.board:m.state.pieces.slice(1).map(p=>[p.x,p.y,p.r])));
    if(id==='drift'){
      for(let i=1;i<m.state.board.length;i++){
        const difference=Math.abs(m.state.board[i]-m.state.board[i-1]);
        assert(difference<=64);assert(difference*1.5/4<78+level*8,'bend lateral speed is steerable');
      }
      assert.equal(center(m.state,0),m.state.pieces[0].x);
      for(let t=0;t<=m.state.goal;t+=.1)assert(Math.abs(center(m.state,t)-DriftLevels.center(m.state,t))<1e-9);
    }else{
      let r=19;const used=new Set();
      for(const id of m.state.target){const q=m.state.pieces.find(p=>p.id===id);assert(q&&!used.has(id)&&q.r<r*.9);
        const x=Math.max(r,Math.min(360-r,q.x)),y=Math.max(r,Math.min(460-r,q.y));
        assert(Math.hypot(x-q.x,y-q.y)<r-q.r*.3,'target remains swallowable at arena edge');
        used.add(id);r=Math.min(70,r+1.3);}
      assert.equal(used.size,m.state.goal);
    }
    m.activate();
    run(m,id==='blackhole'?blackControl:game=>{driftControl(game);stats.driftMaxError[level]=Math.max(stats.driftMaxError[level],Math.abs(game.state.pieces[0].x-center(game.state,game.state.time)));},id==='blackhole'?.3:.2,id==='blackhole'?BlackholeLevels.limit(m.state)+1:51);
    assert.equal(m.state.outcome,1,`${id}/${level}/${seed} t=${m.state.time}`);
    if(id==='blackhole')stats.blackholeMaxSeconds=Math.max(stats.blackholeMaxSeconds,m.state.time);
    const finished=JSON.stringify(m.state);m.tap(0);m.activate();m.aim(0,0);m.step(.008);assert.equal(JSON.stringify(m.state),finished);
    rounds++;
  }
  assert.equal(layouts.size,1000,'different seeds produce different levels');
});
test('equal seeds reproduce layouts; restart rerolls; extreme random sources stay playable',()=>{
  for(const id of ['blackhole','drift'])for(const level of [0,1,2]){
    const a=create(id,level),b=create(id,level);assert.deepEqual(a.state,b.state);
    const previous=JSON.stringify(a.state);a.start(id,level);assert.notEqual(JSON.stringify(a.state),previous);
    for(const value of [0,.999999999,1]){const m=new ExpansionModel({next:()=>value});m.start(id,level);assert(m.valid(m.state));m.activate();run(m,id==='blackhole'?blackControl:driftControl,id==='blackhole'?.3:.2,150);assert.equal(m.state.outcome,1);}
  }
});
test('missing control causes natural losses; a whole car footprint must stay on the road',()=>{
  for(const id of ['blackhole','drift']){const m=create(id);m.activate();run(m,()=>{},.2,150);assert.equal(m.state.outcome,2);}
  const m=create('drift',2);m.activate();m.state.pieces[0].x=center(m.state,0)+43;m.step(.008);assert.equal(m.state.outcome,2);
});
test('seed, geometry and time budgets reject corrupted saves without rerolling valid progress',()=>{
  for(const id of ['blackhole','drift']){
    const m=create(id);m.activate();run(m,id==='blackhole'?blackControl:driftControl,.2,1);
    assert.equal(m.state.outcome,0);const saved=JSON.stringify(m.state),b=create(id,1,10);b.restore(JSON.parse(saved));assert.equal(JSON.stringify(b.state),saved);
    for(const corrupt of id==='blackhole'?[
      s=>s.data[1]++,s=>s.data[2]--,s=>s.target.reverse(),s=>s.pieces[1].x++,s=>s.pieces[1].color=8,s=>s.pieces[1].vx=1
    ]:[s=>s.data[4]++,s=>s.board[2]++,s=>s.pieces[0].vx=1000,s=>s.data[2]+=5]){
      const bad=JSON.parse(saved);corrupt(bad);assert.equal(m.valid(bad),false);
    }
    run(b,id==='blackhole'?blackControl:driftControl,id==='blackhole'?.3:.2,150);assert.equal(b.state.outcome,1);
  }
});
test('legacy blackhole and sine-track saves still restore and finish',()=>{
  for(const id of ['blackhole','drift']){
    const m=create(id);if(id==='blackhole'){m.state.data=[];m.state.target=[];}else{
      m.state.board=[];m.state.data=[0,0,180];m.state.pieces[0].x=180;m.state.pieces[0].vx=85;
    }
    assert(m.valid(m.state));m.activate();run(m,id==='blackhole'?blackControl:driftControl,.2,150);assert.equal(m.state.outcome,1);
  }
});
test('pause, background and continuation retain the same deal and freeze blocked input',()=>{
  for(const id of ['blackhole','drift']){
    const vm=f.vm('ExpansionViewModel');vm.init(id);vm.startGame();vm.activate();vm.advance(96);
    vm.togglePause();let saved=vm.exportContinuation();vm.advance(96);vm.aim(10,10);vm.tap(0);assert.equal(vm.exportContinuation(),saved);
    const receiver=f.vm('ExpansionViewModel');receiver.init(id);assert(receiver.importContinuation(saved));assert.equal(receiver.exportContinuation(),saved);receiver.dispose();
    vm.togglePause();vm.onAppHidden();saved=vm.exportContinuation();vm.advance(96);vm.activate();assert.equal(vm.exportContinuation(),saved);
    vm.onAppShown();vm.advance(96);assert.notEqual(vm.exportContinuation(),saved);vm.dispose();
  }
});
stats.rounds=rounds;console.log(JSON.stringify(stats));console.log(`${count}/${count} toy chase checks passed`);
