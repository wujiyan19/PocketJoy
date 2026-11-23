/* First-party vector game art. Basic SVG geometry only: no fonts, filters, masks,
 * external images or game-brand assets. Shared materials, game-specific silhouettes.
 * Run with Node; source of truth for Collection gameplay materials; icons use generate-game-icons.cjs. */
const fs = require('node:fs');
const path = require('node:path');
const { pruneSvgDefs, writeThemedSvg } = require('./svg-resource-utils.cjs');
const { writeThemedPng } = require('./board-raster.cjs');
const artStyle = require('./game-art-palette.cjs');
const root = path.resolve(__dirname, '..');
const ids = ['tictactoe','gomoku','reversi','fourline','nim','lights','flood','maze','hanoi','peg',
  'nonogram','arithmetic','compare','sequence','binary','targetsum','schulte','memorysequence','missing','reaction'];
const labels = ['井字棋','五子棋','翻转棋','落子四连','取石子','十字熄灯','色块归一','迷宫寻路','汉诺塔','跳子独留',
  '数字绘格','心算十题','算式比大小','数列推演','二进制解码','补数求和','数字寻序','顺序记忆','记忆缺项','信号反应'];
const backgroundsOnly = require.main === module && process.argv.includes('--backgrounds-only');
const selectedBackdrops = backgroundsOnly ? process.argv.slice(2).filter(arg => arg !== '--backgrounds-only') : [];
const assets = new Map();
const rasterWrites = [];
const rect = (x,y,w,h,r,fill,stroke='none',sw=2) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
const circle = (x,y,r,fill,stroke='none',sw=2) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
const line = (d,color,width=3,opacity=1) => `<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" opacity="${opacity}" stroke-linecap="round" stroke-linejoin="round"/>`;
const surfaceGradient = (id,top,bottom) => `<linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1"><stop stop-color="${top}"/><stop offset="1" stop-color="${bottom}"/></linearGradient>`;
const group = (body,x=0,y=0,scale=1,rotate=0) => `<g transform="translate(${x} ${y}) scale(${scale}) rotate(${rotate})">${body}</g>`;
const ellipse = (x,y,rx,ry,color,opacity=1) => `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${color}" opacity="${opacity}"/>`;
const save = (theme,name,w,h,body,defs,raster=false) => {
  const svg=pruneSvgDefs(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><defs>${defs}</defs>${body}</svg>\n`);
  writeThemedSvg(theme,name,svg);
  if (raster) rasterWrites.push(writeThemedPng(theme,name,svg));
  if(theme==='base')assets.set(name,{name,width:w,height:h});
};

for(const theme of ['base','dark']) {
  const dark=theme==='dark';
  const p=artStyle.palette(theme);
  const defs=artStyle.gradients(theme)+
    surfaceGradient('floodGrout',dark?'#304253':'#DCE9EF',dark?'#293B4D':'#D6E3EA')+
    surfaceGradient('nonogramPaper',dark?'#2F3E54':'#FBF8EF',dark?'#29394F':'#F1EFE8')+
    surfaceGradient('memoryMat',dark?'#302F46':'#ECE9F5',dark?'#2A293F':'#E4E1EF');
  const put=(name,w,h,body)=>{ if (!backgroundsOnly) save(theme,name,w,h,body,defs); };
  const backdrop=(name,w,h,body,raster=false)=>{
    if (selectedBackdrops.length === 0 || selectedBackdrops.includes(name)) {
      save(theme,'col_'+name,w,h,body,defs,raster);
    }
  };
  const bevel=(w,h,fill,edge=p.edge,r=16)=>rect(3,5,w-6,h-8,r,edge)+rect(3,2,w-6,h-8,r,fill,edge,1.5)+
    line(`M${r+5} 10H${w-r-6}`, '#FFFFFF',2,.38);
  const grain=(w,h)=>Array.from({length:6},(_,i)=>line(`M14 ${22+i*(h-40)/6}Q${w*.32} ${12+i*(h-40)/6} ${w*.55} ${23+i*(h-40)/6}T${w-14} ${20+i*(h-40)/6}`,p.woodEdge,1,.12)).join('');
  const frame=(fill,edge=p.edge)=>bevel(400,400,fill,edge,24)+rect(15,14,370,370,17,'none',edge,1.5);
  const disc=(color)=>ellipse(50,82,37,9,p.navy,.14)+circle(50,47,38,'url(#'+color+')',p.edge,1.5)+
    ellipse(38,31,15,7,'#FFFFFF',color==='darkstone'?.16:.38)+line('M26 69Q50 85 74 68',p.ink,1.5,.12);
  const cross=line('M29 27L73 71M73 27L29 71','#397ACB',17)+line('M29 23L73 67M73 23L29 67','#9AD2F7',13)+line('M29 21L46 38','#FFFFFF',2,.45);
  const ring=circle(50,51,27,'none','#CF645F',15)+circle(50,47,27,'none','#FFC0A5',13)+line('M29 32Q38 20 53 22','#FFFFFF',2,.45);
  const gem=(color)=>ellipse(50,85,31,7,p.navy,.14)+`<path d="M26 18L74 18L89 40L50 80L11 40Z" fill="url(#${color})" stroke="${p.edge}" stroke-width="1.5"/>`+
    line('M26 18L34 40H66L74 18M11 40H89M34 40L50 80L66 40','#FFFFFF',1.5,.32);
  const stone=ellipse(50,83,34,8,p.navy,.14)+`<path d="M18 42Q20 17 48 16Q79 16 84 47Q91 75 60 79Q27 85 17 65Z" fill="url(#blue)" stroke="${p.edge}" stroke-width="1.5"/>`+
    line('M29 32Q43 21 62 27','#FFFFFF',3,.45)+circle(66,58,4,p.paperLow);
  const peg=ellipse(50,82,32,9,p.navy,.14)+rect(28,43,44,34,17,'url(#gold)',p.woodEdge,1.5)+
    ellipse(50,43,24,17,'#FFE7AD')+ellipse(43,37,12,5,p.white,.45)+line('M28 48V60',p.white,1.5,.38);
  const robot=ellipse(50,87,28,7,p.navy,.14)+rect(21,29,58,49,18,'url(#blue)',p.edge,1.5)+
    rect(29,42,42,21,10,p.navy)+circle(40,52,4,p.white)+circle(60,52,4,p.white)+
    line('M50 29V19',p.edge,4)+circle(50,15,7,p.gold)+rect(16,71,15,15,5,p.paperLow)+rect(69,71,15,15,5,p.paperLow);
  const portal=ellipse(50,83,35,8,p.navy,.14)+rect(21,14,58,71,23,'url(#mint)',p.edge,1.5)+
    rect(32,27,36,55,15,p.navy)+line('M50 39V65M40 55L50 65L60 55',p.white,5)+circle(70,20,5,p.gold);
  const lamp=(on)=>bevel(100,100,on?'url(#glow)':'url(#night)',p.edge,18)+
    circle(50,46,25,on?'#FFE7AD':p.navy,p.edge,1.5)+
    line('M38 39Q50 27 62 39M40 61H60M44 67H56',on?'#C98B3E':'#7E9DB6',4)+
    circle(50,46,11,on?'#FFFDE6':'#27455F');
  const hole=ellipse(50,54,37,32,p.woodLow)+ellipse(50,51,32,27,dark?p.woodInset:'#6C5947')+line('M20 60Q47 91 80 60',p.white,2,.38);
  const pill=(color)=>bevel(100,100,'url(#'+color+')',p.edge,19)+rect(13,14,74,66,12,'none','#FFFFFF',1);
  const card=(back)=>bevel(100,120,back?'url(#violet)':'url(#paper)',p.edge,15)+
    rect(12,12,76,91,10,'none',back?p.white:p.edge,1.5)+
    (back?`<path d="M50 27L60 46L80 56L60 66L50 86L40 66L20 56L40 46Z" fill="#F0E9FF"/>`+circle(50,56,9,'#B1A0E4'):line('M18 25V19H26M82 91V99H74',p.blue,3));
  const chip=(color)=>disc(color)+circle(50,47,23,'none','#FFFFFF',1.3);
  const lantern=(phase)=>{
    const color=phase===2?'mint':phase===1?'gold':'blue';
    return ellipse(50,88,39,8,p.navy,.14)+bevel(100,100,'url(#night)',p.edge,22)+
      circle(50,46,33,p.navy,p.edge,1.5)+circle(50,46,25,'url(#'+color+')')+
      (phase===2?line('M35 46L46 57L65 34','#F4FFED',6):phase===1?line('M50 29V47L61 54','#654624',5):`<path d="M43 32L64 46L43 60Z" fill="#EFF7FF"/>`)+
      [30,50,70].map((x,i)=>rect(x-6,84,12,4,2,i===phase?'#C4F5DE':'#4D6B8B')).join('');
  };
  const pieces={stone_dark:disc('darkstone'),stone_light:disc('whitestone'),cross,ring,chip_blue:chip('blue'),chip_coral:chip('coral'),
    stone,peg,robot,portal,light_on:lamp(true),light_off:lamp(false),peg_hole:hole};
  for(const [name,body] of Object.entries(pieces))put('col_'+name,100,100,body);
  for(const color of ['blue','mint','gold','coral','violet'])put('col_gem_'+color,100,100,gem(color));
  ['blue','mint','gold','coral'].forEach((c,i)=>put('col_flood_'+i,100,100,pill(c)));
  put('col_card_front',100,120,card(false));put('col_card_back',100,120,card(true));
  put('col_ceramic_cell',100,100,bevel(100,100,'url(#tile)',p.edge,14));
  put('col_paper_cell',100,100,rect(1,1,98,98,6,p.paper,p.edge,1.5)+line('M9 14H34',p.edge,1.5,.3));
  put('col_ink_cell',100,100,rect(1,1,98,98,6,'url(#blue)',p.edge,1.5)+line('M16 77L73 20M32 85L84 33',p.white,3,.25));
  put('col_go_cell',100,100,line('M0 50H100M50 0V100',p.woodEdge,2));
  put('col_jade_cell',100,100,rect(1,1,98,98,5,'none',p.mint,1.5));
  put('col_drop_hole',100,100,circle(50,50,42,'url(#ink)',p.edge,1.5)+circle(50,54,33,p.navy));
  put('col_path',100,100,rect(0,0,100,100,5,dark?'#36494D':'#E1E4C7')+
    line('M18 32L36 25M59 79L72 73',dark?'#526665':'#BDCAA7',3));
  put('col_wall',100,100,rect(0,6,100,94,9,dark?'#243C3D':'#3C7065')+
    rect(2,2,96,85,13,dark?'#3D6961':'#7FAE8D',dark?'#294E47':'#68947A',2)+
    line('M11 24Q30 6 49 23M55 68Q77 49 88 64',dark?'#547E70':'#ADD0A2',5,.7));
  put('col_jade_board',400,400,frame('url(#jade)',dark?'#3A655C':p.mint));
  put('col_blue_board',400,400,frame('url(#blue)',p.edge));
  put('col_table_tray',500,190,bevel(500,190,'url(#wood)',p.woodEdge,22)+grain(500,190)+rect(14,16,472,156,16,'none',p.woodEdge,1.5));
  put('col_hanoi_post',120,220,rect(53,13,14,177,7,'url(#wood)',p.woodEdge,2)+
    group(bevel(120,30,'url(#wood)',p.woodEdge,10),0,187)+circle(60,16,5,'#F5D4A0'));
  for(let i=0;i<5;i++)put('col_disc_'+i,180,40,bevel(180,40,'url(#'+['blue','mint','gold','coral','violet'][i]+')',p.edge,18));
  for(let i=0;i<3;i++)put('col_signal_'+i,100,100,lantern(i));

  // The inlay stays quiet between the live controls. Material detail lives in the rim.
  const rim=(w,h,fill,edge,highlight,r)=>
    rect(2,5,w-4,h-6,r,edge)+rect(2,1,w-4,h-7,r,fill,edge,2)+
    rect(9,8,w-18,h-21,r-5,'none',highlight,1.6)+
    line(`M${r+6} 5H${w-r-6}M6 ${r+8}V${h-r-14}`,highlight,2,.68);
  backdrop('table_board',400,400,rim(400,400,'url(#wood)',p.woodEdge,dark?'#AA8262':'#F8DEB5',25)+
    rect(20,19,360,357,19,'none',p.woodInset,2)+
    line('M24 53Q59 32 109 44T179 41M21 59Q64 44 105 50T150 50M24 78Q45 63 80 67M253 358Q292 348 329 355T376 344M275 366Q327 373 375 354',p.woodEdge,2,.45)+
    line('M27 29H77M323 370H372',p.white,2,dark?.23:.5));
  const gardenEdge=dark?'#41685C':'#7E9D79';
  const gardenHighlight=dark?'#75A391':'#EDF5D6';
  backdrop('garden_board',400,400,rim(400,400,dark?'#324B46':'#D4E1BF',gardenEdge,gardenHighlight,26)+
    rect(16,15,368,366,20,'none',gardenEdge,2.5)+
    line('M19 51Q17 24 49 19M381 341Q384 372 352 377',gardenHighlight,4,.7)+
    line('M44 12H127M275 383H352',gardenEdge,2.5,.55));
  const enamelEdge=dark?'#0C1729':'#284565';
  const enamelHighlight=dark?'#496987':'#80A6BD';
  backdrop('night_board',400,400,rim(400,400,'url(#night)',enamelEdge,enamelHighlight,26)+
    rect(17,16,366,362,20,'none',enamelHighlight,2)+
    line('M26 37V26H66M334 26H372V37M26 350V369H66M334 369H372V350',enamelHighlight,2,.82)+
    line('M101 12H164M175 12H186M220 384H295',p.cyan,2,.45));
  const ceramicEdge=dark?'#516681':'#9FBBD0';
  const ceramicGlaze=dark?'#6883A0':'#F8FCFF';
  backdrop('ceramic_board',400,400,rim(400,400,dark?'#293951':'#D6E5EE',ceramicEdge,ceramicGlaze,26)+
    rect(16,16,368,363,17,'none',ceramicEdge,2)+
    line('M21 75V36Q21 22 38 22H75M379 321V357Q379 373 365 373H327',ceramicGlaze,3,.78));
  backdrop('flood_board',400,400,rect(0,0,400,400,7,'url(#floodGrout)'));
  const paperEdge=dark?'#516783':'#B4C3C8';
  const paperGlaze=dark?'#607893':'#FFFFFF';
  backdrop('paper_board',400,400,rect(0,0,400,400,9,'url(#nonogramPaper)'));
  backdrop('hanoi_station',120,220,
    rect(7,209,106,8,4,dark?'#806A55':'#D8BF99')+
    line('M15 215H105',dark?'#A58B70':'#F2DEC0',1.1,.65));
  backdrop('memory_board',400,400,rect(0,0,400,400,14,'url(#memoryMat)'),true);
  const signalRim=dark?'#AACDE1':'#4D718C';
  backdrop('signal_stage',400,420,
    rect(9,8,382,401,34,'none',signalRim,2)+
    line('M20 117V48Q20 20 48 20H105M295 20H352Q380 20 380 48V117M20 299V370Q20 397 48 397H105M295 397H352Q380 397 380 370V299',signalRim,3,dark?.27:.35)+
    line('M22 183V237M378 183V237M170 20H230M170 398H230',signalRim,3,.22)+
    line('M25 88Q75 56 107 40M293 378Q325 362 375 330',signalRim,2,.17));

  // One question-card silhouette with mode-specific embossing outside the text area.
  const questionPaper=rim(500,200,dark?'#2B374D':'#FAF4E8',paperEdge,paperGlaze,23);
  const questionBlue=dark?'#84ACC8':'#5186AA';
  const questionWarm=dark?'#CCAB96':'#AA7559';
  const questionAccent=dark?'#A5A2CE':'#8576AD';
  const question=(name,details)=>backdrop('question_'+name,500,200,questionPaper+details,true);
  question('paper',line('M25 55V25H69M25 37H36M43 25V34M54 25V31M462 144V172H420M462 161H451M450 172V164M439 172V166',questionBlue,2,.54));
  question('compare',line('M82 26H43Q28 26 28 40V55M70 35H49Q39 35 39 44V58',questionBlue,2.8,.57)+
    line('M418 26H457Q472 26 472 40V55M430 35H451Q461 35 461 44V58',questionWarm,2.8,.57)+
    line('M35 162H73M427 162H465',questionAccent,2,.46));
  question('sequence',line('M30 47H45V35H59V23H75M417 171H433V159H447V147H464',questionAccent,3,.55)+
    line('M31 169H70M432 24H466',questionBlue,2,.39));
  question('binary',line('M23 59V32H55V23H90M24 159H46V175H78M476 39H453V24H414M475 143V170H450V177H408',questionBlue,2.5,.52)+
    circle(95,23,3.6,questionBlue)+circle(407,177,3.6,questionBlue));
  question('targetsum',line('M23 50Q45 19 82 24M34 52Q51 32 78 33M418 174Q450 180 475 149M423 165Q449 169 464 150',questionWarm,3,.55)+
    line('M25 159H66M432 38H475',questionBlue,2,.42));
  put('col_question_memory',500,200,bevel(500,200,'url(#paper)',p.edge,20)+
    [22,478].map(x=>circle(x,32,5,'#B2A0E0')+circle(x,166,5,'#B2A0E0')).join('')+
    line('M55 15H445M55 179H445','#A999D0',2,.3));

}
const manifestPath = path.join(root, 'docs/art/collection-art-manifest.json');
if (backgroundsOnly) {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const entries = new Map(manifest.assets.map(asset => [asset.name, asset]));
  for (const [name, asset] of assets) entries.set(name, asset);
  manifest.assets = [...entries.values()];
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
  console.log(`Generated ${assets.size} background SVG resources × 2 themes.`);
} else {
  // Icon geometry is owned by the shared 100-game generator.
  for (const id of ids) assets.set('game_'+id,{name:'game_'+id,width:120,height:120});
  const manifest={style:'LittleGames / soft tactile miniatures',source:'First-party SVG geometry; no external assets',games:ids.map((id,i)=>({id,name:labels[i],icon:'game_'+id})),assets:[...assets.values()]};
  const updateElements=(theme,type,values)=>{
    const file=path.join(root,'entry/src/main/resources',theme,'element',type+'.json');
    const data=JSON.parse(fs.readFileSync(file,'utf8'));
    for(const [name,value] of Object.entries(values)){
      const item=data[type].find(x=>x.name===name);if(item)item.value=value;else data[type].push({name,value});
    }
    fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n');
  };
  updateElements('base','color',{collection_art_ink:artStyle.palette('base').ink});
  updateElements('dark','color',{collection_art_ink:artStyle.palette('dark').ink});
  updateElements('base','float',{
    collection_art_beacon:'88vp',collection_art_turn:'32vp',collection_art_question_icon:'48vp',
    collection_art_question_height:'180vp',collection_art_card_width:'44vp',collection_art_card_height:'56vp',
    collection_art_stone:'36vp',collection_art_tray_height:'190vp',collection_art_disc_height:'26vp',collection_art_tower_height:'232vp'
  });
  fs.mkdirSync(path.dirname(manifestPath),{recursive:true});
  fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n');
  console.log(`Generated ${assets.size} SVG resources × 2 themes (including 20 game-specific icons).`);
  require('./generate-game-icons.cjs').generate();
}

Promise.all(rasterWrites).catch(error => {
  console.error(error);
  process.exitCode = 1;
});
module.exports={ids,labels};
