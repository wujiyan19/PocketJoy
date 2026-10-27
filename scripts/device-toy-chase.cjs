/* Real rendered UI on an explicit HDC target. Never imports rules or reads app files. */
const c=require('./device-toy-art.cjs');
const python=process.env.LITTLEGAMES_PIXEL_PYTHON||'C:/Users/29186/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe';
function screenshot(tag){c.shell('snapshot_display','-f','/data/local/tmp/lg-chase.jpeg');const file=c.path.join(c.dir,tag+'.jpeg');c.run('file','recv','/data/local/tmp/lg-chase.jpeg',file);return file;}
function pixels(file,area,game){return JSON.parse(c.cp.execFileSync(python,['scripts/toy-chase-pixels.py',file,JSON.stringify(area),game],{encoding:'utf8',stdio:['ignore','pipe','pipe']}));}
function difficulty(label){let ns=c.layout();c.click(ns.find(n=>n.id==='game-settings-button'));ns=c.wait(a=>c.find(a,label));c.tap(label,ns);c.sleep(200);ns=c.layout();if(ns.some(n=>n.id==='game-settings-panel'))c.click(ns.find(n=>n.id==='game-settings-return'));return c.wait(a=>!a.some(n=>n.id==='game-settings-panel'));}
function result(ns){return !!c.find(ns,'再来一局');}
function blackhole(){
  let ns=c.layout();if(!ns.some(n=>n.id==='toy-blackhole-scene'))ns=c.open('blackhole');
  c.capture('blackhole-start-ready');if(c.find(ns,'点击开始'))c.tap('点击开始',ns);
  let previous=null,progress=-1,blocked=[];
  for(let i=0;i<80;i++){
    ns=c.layout();if(result(ns)){c.capture('blackhole-result');c.assert(c.text(ns).includes('挑战完成'),'Natural win required');c.log('chase-win',{game:'blackhole',steps:i});return;}
    const current=Number(c.text(ns).find(t=>t.startsWith('进度 ')).match(/\d+/)[0]);
    if(current!==progress)blocked=[];else if(previous)blocked.push(previous);progress=current;
    const area=c.bounds(ns.find(n=>n.id==='toy-blackhole-scene')),scale=(area[2]-area[0])/360;
    const file=screenshot('blackhole-motion'),p=pixels(file,area,'blackhole');
    p.rings=p.rings.filter(q=>!blocked.some(b=>Math.hypot(b.x-q.x,b.y-q.y)<20));
    c.assert(p.rings.length,'Visible edible ring required');p.rings.sort((a,b)=>Math.hypot(a.x-p.hole.x,a.y-p.hole.y)-Math.hypot(b.x-p.hole.x,b.y-p.hole.y));
    const q=p.rings[0],distance=Math.hypot(q.x-p.hole.x,q.y-p.hole.y)/scale;
    previous=q;
    c.log('blackhole-screen-control',{hole:p.hole,aim:q,rings:p.rings.length});
    c.shell('uitest','uiInput','click',''+Math.round(q.x),''+Math.round(q.y));
    c.sleep(Math.min(1800,Math.max(150,Math.round(distance/145*1000+170))));
    if(i===2)c.capture('blackhole-grown');
  }throw Error('Natural blackhole settlement absent');
}
function drift(){
  let ns=c.layout();if(!ns.some(n=>n.id==='toy-drift-board'))ns=c.open('drift');
  difficulty('简单');ns=c.capture('drift-easy-ready');
  const area=c.bounds(ns.find(n=>n.id==='toy-drift-board'));
  const button=c.find(ns,'点击开始');c.assert(button);const bounds=c.bounds(button),bx=Math.round((bounds[0]+bounds[2])/2),by=Math.round((bounds[1]+bounds[3])/2);
  c.shell('uinput','-T','-c',''+bx,''+by,'20');
  let turns=0;
  const started=Date.now();
  while(Date.now()-started<65000){
    const file=screenshot('drift-motion');let p;try{p=pixels(file,area,'drift');}catch(e){break;}
    const error=(p.car-p.center)/p.scale;
    c.log('drift-screen-control',{...p,error});
    if(error*p.direction> -35){
      c.shell('uinput','-T','-c',''+bx,''+by,'20');turns++;
    }
    if(turns===2&&!c.fs.existsSync(c.path.join(c.dir,'drift-turning.jpeg')))c.fs.copyFileSync(file,c.path.join(c.dir,'drift-turning.jpeg'));
  }
  ns=c.capture('drift-result');c.assert(result(ns),'Natural settlement required');
  c.log('drift-screen-settlement',{turns,win:c.text(ns).includes('挑战完成'),text:c.text(ns)});
  console.log(JSON.stringify({turns,text:c.text(ns)}));
}
function leave(){let ns=c.layout();c.click(ns.find(n=>n.type==='Button'&&c.bounds(n)[0]<200&&c.bounds(n)[1]<300));c.sleep(800);ns=c.layout();if(c.find(ns,'确认退出？')){c.tap('退出',ns);c.sleep(800);}c.assert(c.layout().some(n=>n.type==='TextInput'));}
function fronts(){
  c.open('drift');c.capture('drift-light-ready');leave();
  c.theme('dark');c.open('blackhole');c.capture('blackhole-dark');leave();
  c.open('drift');c.capture('drift-dark');leave();c.theme('restore');
  c.log('chase-fronts-checked',{games:['blackhole','drift'],themes:['light','dark'],restoredTheme:true});
}
const action=process.argv[2];
try{if(action==='blackhole')blackhole();else if(action==='drift')drift();else if(action==='fronts')fronts();else if(action==='difficulty')difficulty(process.argv[3]);else throw Error('Expected blackhole, drift, fronts or difficulty');}catch(e){console.error(e);process.exitCode=1;}
