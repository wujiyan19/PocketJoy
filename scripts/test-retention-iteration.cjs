/* Acceptance for the approved catalog/mode/replay changes, using real ArkTS models. */
const assert=require('node:assert/strict');
const {fixture,Frames}=require('./test-performance.cjs');
const {steerTank}=require('./retention-game-controls.cjs');
const f=fixture(),{ExpansionModel}=f.rules('Expansion'),{CollectionModel}=f.rules('Collection');
const tests=[],test=(name,run)=>tests.push({name,run});
const create=(id,level,seed)=>{const m=new ExpansionModel(f.rng(seed*7919));m.start(id,level);return m;};
test('64 entries contain all seven withdrawals and five merged modes without deleting old scores',()=>{
  const local=fixture({highScores:JSON.stringify({compare:1234,beatjump:2800,jumpjump:90})});const data=local.data();data.init({});
  const routes=local.load('entry/src/main/ets/router/GameRouteRegistry.ets').GameRoutes;
  for(const id of ['jumpjump','slotpair','missing','sand','linerescue','bowling','pipes','compare','sequence','binary','targetsum','beatjump']){
    assert.equal(data.getGameById(id),undefined);assert.equal(routes.routeName(id),'');
  }
  assert.equal(data.getAllGames().length,64);assert.equal(routes.getAllGameRoutes().length,64);assert.equal(routes.gameIdForRoute(''),'');
  data.recordMode('compare','easy',100);data.flushNow();
  assert.equal(JSON.parse(local.values.get('highScores')).compare,1234);
  const next=fixture(Object.fromEntries(local.values));next.data().init({});
  assert.equal(next.data().getModeScore('compare','easy'),100);assert.equal(next.data().getModeScore('compare','hard'),0);
  assert.equal(next.data().archivedModeScore('beatjump'),2800);
});
test('all five math modes finish, keep separate records and restore under the parent ID',()=>{
  const local=fixture(),data=local.data();data.init({});const vm=local.vm('CollectionViewModel');vm.init('arithmetic');vm.startGame();
  for(const mode of ['arithmetic','compare','sequence','binary','targetsum']){
    vm.changeMode(mode);if(vm.state.outcome)vm.startGame();assert.equal(vm.state.id,mode);
    for(let round=0;round<10;round++)vm.choose(vm.state.choices.indexOf(vm.state.answer));
    assert.equal(vm.state.outcome,1);assert.equal(data.getModeScore(mode,'normal'),2000);
    const target=local.vm('CollectionViewModel');target.init('arithmetic');assert(target.importContinuation(vm.exportContinuation()));assert.equal(target.modeId,mode);target.dispose();
  }
  vm.dispose();
});
test('merged histories fold into parent entries without losing time or double-counting new sessions',()=>{
  const local=fixture({highScores:'{"arithmetic":200,"compare":800,"binary":500}',
    playTimesMs:'{"arithmetic":100,"compare":200,"binary":300,"rhythm":200,"beatjump":600}',
    gameStartCounts:'{"arithmetic":4,"compare":3,"binary":2,"beatjump":2}',
    playedGames:'["compare","binary","beatjump"]',recentGames:'["beatjump","binary","compare"]',
    lastPlayedAt:'{"compare":3000,"binary":2000,"beatjump":5000}'});
  const d=local.data();d.init({});assert.equal(d.getPlayedGameCount(),2);assert.equal(d.getTotalPlayTimeMs(),1400);
  assert.equal(d.getGameById('arithmetic').highScore,800);assert.equal(d.getPlayCount('arithmetic'),9);
  assert.deepEqual(d.getPlayHistory().map(r=>r.game.id),['rhythm','arithmetic']);
  assert.deepEqual(d.getRecentlyPlayed().map(g=>g.id),['rhythm','arithmetic']);
  d.recordGameStarted('arithmetic');d.addPlayTime('arithmetic',50);d.flushNow();
  const next=fixture(Object.fromEntries(local.values));next.data().init({});
  assert.equal(next.data().getPlayCount('arithmetic'),10);assert.equal(next.data().getGameById('arithmetic').playTimeMs,650);
  assert.equal(JSON.parse(local.values.get('playTimesMs')).compare,200);
});
test('old independent math and beat-jump continuations migrate to parent entries',()=>{
  for(const id of ['compare','sequence','binary','targetsum','beatjump']){
    const local=fixture(),isBeat=id==='beatjump',vm=local.vm(isBeat?'ExpansionViewModel':'CollectionViewModel');vm.init(id);vm.startGame();
    const app=local.load('entry/src/main/ets/common/AppContinuation.ets').AppContinuation;let received;
    app.connect(()=>({tab:0,paths:[]}),s=>{received=s;});
    assert(app.receive(JSON.stringify({version:1,tab:0,paths:[(isBeat?'Expansion_':'Collection_')+id],gameId:id,gamePayload:vm.exportContinuation()})));
    assert.equal(received.gameId,isBeat?'rhythm':'arithmetic');
    const restored=local.vm(isBeat?'ExpansionViewModel':'CollectionViewModel');restored.init(received.gameId);assert(restored.importContinuation(received.gamePayload));assert.equal(restored.state.id,id);
    restored.dispose();vm.dispose();app.disconnect();
  }
});
test('rhythm parent runs and continues the three-key mode with its own score',()=>{
  const local=fixture(),frames=new Frames(),vm=local.vm('ExpansionViewModel');local.data().init({});vm.init('rhythm',frames);vm.startGame();vm.changeMode('beatjump');vm.activate();
  for(let i=0;i<10000&&!vm.isFinished;i++){if(Math.abs(vm.state.cooldown)<.015)vm.tap(vm.state.target[vm.state.cursor]);frames.tick(8);}
  assert.equal(vm.state.outcome,1);assert(local.data().getModeScore('beatjump','normal')>0);assert.equal(local.data().getModeScore('rhythm','normal'),0);vm.dispose();
});
test('numeric search records active milliseconds, excludes background, and preserves them on restore',()=>{
  const local=fixture(),vm=local.vm('CollectionViewModel');local.data().init({});vm.init('schulte');vm.startGame();
  local.clock.advance(1050);vm.onAppHidden();local.clock.advance(5000);vm.onAppShown();local.clock.advance(550);
  for(let value=1;value<=vm.state.board.length;value++)vm.tap(vm.state.board.indexOf(value));
  assert.equal(vm.state.outcome,1);assert.equal(vm.state.elapsedMs,1600);assert.equal(local.data().getModeTime('schulte','normal'),1600);
  const restored=local.vm('CollectionViewModel');restored.init('schulte');assert(restored.importContinuation(vm.exportContinuation()));assert.equal(restored.state.elapsedMs,1600);restored.dispose();vm.dispose();
});
test('changing 2048 rules or mole difficulty cannot attribute an old score to the new selection',()=>{
  for(const name of ['Game2048','WhackMole']){
    const local=fixture(),vm=local.vm(name+'ViewModel',local.rng(7));local.data().init({});vm.startGame();vm.score=30;vm.changeDifficulty('hard');
    const id=vm.continuationGameId();assert.equal(local.data().getModeScore(id,'normal'),30);assert.equal(local.data().getModeScore(id,'hard'),0);vm.dispose();
  }
});
test('an old 40-second mole round continues, with its result separated from new 30-second records',()=>{
  const local=fixture(),vm=local.vm('WhackMoleViewModel',local.rng(3));local.data().init({});vm.startGame();
  const old=JSON.parse(vm.exportContinuation());delete old.rulesVersion;old.difficulty='easy';old.timeLeft=40;old.score=75;
  assert(vm.importContinuation(JSON.stringify(old)));assert.equal(vm.timeLeft,40);assert.equal(vm.getGameTime(),40);
  vm.onAppHidden();assert.equal(local.data().getModeScore('whackmole','legacy_easy'),75);assert.equal(local.data().getModeScore('whackmole','easy'),0);
  vm.startGame();assert.equal(vm.timeLeft,30);assert.equal(vm.isLegacyRound(),false);vm.dispose();
});
test('new deals vary actual geometry, graph structure and pictures, with a fixed block-fit area',()=>{
  for(const level of [0,1,2]){
    for(const id of ['sokoban','untangle','platformer','grapple','rollingball','hillclimb','picturepuzzle','tanks']){
      const layouts=new Set();for(let seed=1;seed<=30;seed++){
        const m=create(id,level,seed);assert(m.valid(m.state),id);
        layouts.add(JSON.stringify(id==='picturepuzzle'?m.state.variant:id==='sokoban'||id==='untangle'||id==='hillclimb'?m.state.board:m.state.pieces.filter(p=>[25,26,27,28].includes(p.kind))));
      }
      assert(layouts.size>=3,id+'/'+level+' needs different tasks');
    }
    assert.equal(create('blockfit',level,1).state.board.length,36);
    const rules=new(f.rules('Klotski').KlotskiRules)(4,5),difficulty=['easy','normal','hard'][level];
    assert(new Set(Array.from({length:30},(_,i)=>JSON.stringify(rules.deal(difficulty,f.rng((i+1)*7919))))).size>3);
  }
});
test('Sudoku grades use techniques in addition to clues, and nonograms finish by line deduction',()=>{
  const rules=new(f.rules('Sudoku').SudokuRules)();
  for(let level=0;level<3;level++)for(let seed=1;seed<=30;seed++){
    const p=rules.generatePuzzle(['easy','normal','hard'][level],'',f.rng(seed*7919)).puzzle;
    assert.equal(rules.logicRating(p),level);assert.equal(rules.countSolutions(p),1);
    const c=new CollectionModel(f.rng(seed*7919));c.start('nonogram',level);assert(c.deducibleNonogram());
    c.state.markEmpty=true;c.tap(0);assert.equal(c.state.board[0],2);
  }
});
test('legacy real snapshots still restore after the replay changes',()=>{
  const snapshots=require('./fixtures/retention-legacy-saves.json');
  for(const item of snapshots){
    const local=fixture(),vm=local.vm(item.family==='collection'?'CollectionViewModel':'ExpansionViewModel');vm.init(item.state.id);
    const payload=JSON.stringify({version:1,state:item.state,recorded:false,paused:false});
    assert(vm.importContinuation(payload),item.state.id+'/'+item.state.level);vm.dispose();
  }
});
for(const id of ['platformer','grapple','rollingball','hillclimb','tanks','survival','fishing'])test(id+': 90 randomized complete games through public controls',()=>{
  for(let level=0;level<3;level++)for(let seed=1;seed<=30;seed++){
    const m=create(id,level,seed);m.activate();let waypoint=0;
    const path=id==='rollingball'?Array.from({length:m.state.target.length/2},(_,i)=>m.state.target.slice(i*2,i*2+2)):[];
    for(let i=0;i<18000&&!m.state.outcome;i++){
      const p=m.state.pieces[0],t=i*.008;
      if(id==='platformer'){
        m.tap(1);const ground=m.state.pieces.find(q=>q.kind===25&&p.x>=q.x-10&&p.x<=q.x+q.w+10&&Math.abs(p.y+p.r-q.y)<2);
        if(ground&&p.vy===0&&p.x>=ground.x+ground.w-30)m.tap(2);
      }
      if(id==='grapple'){if(m.state.selected>=0){const anchor=m.state.pieces.find(q=>q.id===m.state.selected);if(p.x>anchor.x+35){m.tap(1);m.tap(0);}}else m.tap(0);}
      if(id==='rollingball'){const w=path[Math.min(waypoint,path.length-1)];if(Math.hypot(p.x-w[0],p.y-w[1])<10)waypoint++;m.aim(w[0],w[1]);}
      if(id==='hillclimb')m.tap(0);
      if(id==='tanks'&&i%12===0)steerTank(m);
      if(id==='survival'){m.aim(180+Math.sin(t*.6)*145,370+Math.cos(t*.6)*50);if(m.state.data[1]>=20)m.tap(m.state.data[0]<2?2:m.state.board[0]<2?0:1);}
      if(id==='fishing'){if(m.state.data[0]===0||m.state.data[0]===2)m.tap(0);if(m.state.data[0]===3)m.tap(m.state.data[2]<62?1:2);}
      m.step(.008);
    }
    assert.equal(m.state.outcome,1,id+'/'+level+'/'+seed);assert(m.valid(m.state),id+' finished snapshot');
  }
});
let failures=0;
for(const t of tests){try{t.run();console.log('PASS '+t.name);}catch(e){failures++;console.error('FAIL '+t.name+'\n'+e.stack);}}
console.log(`${tests.length-failures}/${tests.length} retention iteration checks passed`);process.exitCode=failures?1:0;
