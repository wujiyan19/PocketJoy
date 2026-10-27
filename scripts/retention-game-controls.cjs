/* Model input controller used by completion and randomized retention checks. */
function steerTank(model) {
  const s=model.state, player=s.pieces[0];
  const enemies=s.pieces.filter(p=>p.kind===33), bullets=s.pieces.filter(p=>p.kind===34&&p.owner===1), walls=s.pieces.filter(p=>p.kind===26);
  let best=[player.x,player.y],value=-Infinity;
  for(const x of [30,135,180,225,330])for(const y of [60,110,210,285,385,430]){
    if(walls.some(w=>x+18>w.x&&x-18<w.x+w.w&&y+18>w.y&&y-18<w.y+w.h))continue;
    const targets=enemies.slice().sort((a,b)=>Math.hypot(a.x-x,a.y-y)-Math.hypot(b.x-x,b.y-y));
    const distance=targets.length?Math.hypot(targets[0].x-x,targets[0].y-y):200;
    const danger=Math.min(200,...bullets.map(b=>Math.hypot(b.x+b.vx*.2-x,b.y+b.vy*.2-y)));
    const e=targets[0];let clear=true;
    if(e)for(let i=1;i<30;i++){const px=x+(e.x-x)*i/30,py=y+(e.y-y)*i/30;if(walls.some(w=>px>=w.x&&px<=w.x+w.w&&py>=w.y&&py<=w.y+w.h)){clear=false;break;}}
    const score=Math.min(distance,150)*2+Math.min(danger,120)+(clear?160:0)-(distance<70?600:0)-(danger<45?600:0)-Math.hypot(x-player.x,y-player.y)*.12;
    if(score>value){value=score;best=[x,y];}
  }
  model.aim(best[0],best[1]);
}
module.exports={steerTank};
