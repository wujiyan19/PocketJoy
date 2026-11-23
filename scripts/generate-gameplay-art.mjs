/** The original thirteen games share the soft vector materials of their current icons. */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import artStyle from './game-art-palette.cjs';
import boardRaster from './board-raster.cjs';
import svgResources from './svg-resource-utils.cjs';
const { pruneSvgDefs, writeThemedSvg } = svgResources;
const { writeThemedPng } = boardRaster;
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rect = (x,y,w,h,r,fill,stroke='none',sw=2) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
const ellipse = (x,y,rx,ry,fill,opacity=1) => `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${fill}" opacity="${opacity}"/>`;
const circle = (x,y,r,fill,stroke='none',sw=2) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
const shape = (d,fill,stroke='none',sw=2) => `<path d="${d}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
const line = (d,color,w=2,opacity=1) => `<path d="${d}" fill="none" stroke="${color}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" opacity="${opacity}"/>`;
const gradient = (id, top, bottom, x2='0%') => `<linearGradient id="${id}" x1="0%" y1="0%" x2="${x2}" y2="100%"><stop stop-color="${top}"/><stop offset="100%" stop-color="${bottom}"/></linearGradient>`;
const selected = new Set(process.argv.slice(2));
const rasterBackgrounds = new Set(['tetris_board', '2048_board', '2048_well', 'mine_board', 'sudoku_board',
  'slide_board', 'guess_panel', 'memory_board', 'match3_board', 'match3_well']);
const rasterJobs = [];
const generated = [];
for (const theme of ['base','dark']) {
  const dark = theme === 'dark', p = artStyle.palette(theme), defs = artStyle.gradients(theme);
  if (selected.size === 0) {
    const colorFile = path.join(root,`entry/src/main/resources/${theme}/element/color.json`);
    const resources = JSON.parse(fs.readFileSync(colorFile,'utf8'));
    const colors = artStyle.resourceColors(theme);
    for (const [name,value] of Object.entries(colors)) {
      const existing = resources.color.find(color=>color.name===name);
      if (existing) existing.value=value;
      else resources.color.push({name,value});
    }
    fs.writeFileSync(colorFile,JSON.stringify(resources,null,2)+'\n');
  }
  const saveSvg = (name,w,h,svg) => {
    const resource = 'play_' + name;
    if (selected.size === 0 || selected.has(name)) {
      const artwork = pruneSvgDefs(svg);
      writeThemedSvg(theme, resource, artwork);
      if (rasterBackgrounds.has(name)) rasterJobs.push(writeThemedPng(theme, resource, artwork));
    }
    if (theme === 'base') generated.push({ name:resource, width:w, height:h });
  };
  const save = (name,w,h,body,artDefs=defs) => saveSvg(name,w,h,`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><defs>${artDefs}</defs>${body}</svg>\n`);
  const surface = (w,h,edge,corner=18) => rect(0,0,w,h,corner,edge) + rect(4,4,w-8,h-8,corner-4,'url(#face)') +
    line(`M${corner+1} 6H${w-corner-1}`,p.white,2,dark?.17:.53);
  const tile = (w,h,color,r=12) => rect(3,5,w-6,h-8,r,p.edge)+rect(3,2,w-6,h-8,r,`url(#${color})`,p.edge)+
    line(`M${r+5} 9H${w-r-8}`,'#FFFFFF',2,.48);
  const gloss = (w,h,r=12) => rect(2,2,w-4,h-4,r,'none',p.edge,2)+
    line(`M${r+4} 8H${w-r-6}`,'#FFFFFF',3,dark?.3:.5)+line(`M${r+4} ${h-8}H${w-r-4}`,p.edge,2,.36);
  // Right-facing head. Openings of body, elbow and tail retain the existing connection directions.
  save('snake_head',100,100,shape('M0 25H30C38 10 64 8 80 23C101 39 100 63 83 77C66 92 40 88 30 75H0Z','url(#mint)','#4D9E85',2)+
    ellipse(68,34,12,11,'#FFFAF0')+ellipse(68,67,12,11,'#FFFAF0')+circle(72,34,5,'#304A69')+circle(72,67,5,'#304A69')+
    ellipse(84,51,11,7,'#C7EDD0')+line('M90 51H96L99 46M96 51L99 56',p.coral,3));
  save('snake_body',100,100,rect(0,25,100,50,0,'url(#mint)')+line('M0 25H100M0 75H100','#4D9E85',2)+line('M0 33H100','#D8F6DB',3,.55));
  save('snake_corner',100,100,shape('M0 25H50C64 25 75 36 75 50V100H25V75H0Z','url(#mint)')+
    line('M0 25H50C64 25 75 36 75 50V100M0 75H25V100','#4D9E85',2)+line('M0 33H50Q67 33 67 50V100','#D8F6DB',3,.5));
  save('snake_tail',100,100,shape('M100 25H73C48 25 17 38 2 50C17 62 48 75 73 75H100Z','url(#mint)','#4D9E85',2)+line('M100 33H74Q43 33 16 49','#D8F6DB',3,.5));
  save('snake_food',64,64,shape('M32 19C20 10 8 20 9 34C10 49 23 57 32 52C42 57 54 48 55 34C56 20 43 10 32 19Z','url(#coral)',p.edge)+
    line('M32 21Q33 11 39 7',p.woodEdge,3)+shape('M36 13Q44 3 54 7Q48 17 36 13Z','url(#mint)')+ellipse(21,29,5,3,'#FFFFFF',.5));
  save('tetris_gloss',100,100,gloss(100,100,12));
  save('2048_surface',100,100,gloss(100,100,14));
  save('sudoku_cell',100,100,rect(1,1,98,98,5,'none',p.edge,1)+line('M9 10H33','#FFFFFF',2,dark?.18:.4));
  save('slide_tile',100,100,gloss(100,100,12));
  save('guess_key',100,100,gloss(100,100,12));
  const mapleEdge = dark?'#241E19':'#D9C3A3';
  const mapleGrain = dark?'#68513C':'#B29872';
  save('klotski_board',320,400,rect(3,3,314,394,22,mapleEdge)+
    rect(5,5,310,387,19,'none',dark?'#634C37':'#C6AA88',2)+
    rect(13,12,294,374,14,'url(#face)',mapleGrain,2)+
    line('M15 37V30Q15 15 30 15H290M307 366Q304 382 288 384H34',dark?'#171410':'#BDA282',2,.29)+
    line('M27 8H293M8 29V368',p.white,1.5,dark?.10:.48)+
    line('M24 53H146M186 78H299M22 158H193M126 237H300M26 300H132M165 341H296',mapleGrain,1,.19)+
    [113,286].map(y=>rect(7,y,4,12,1.5,p.gold)+rect(309,y,4,12,1.5,p.gold)).join('')+
    line('M118 389H202',p.gold,6)+line('M135 373L160 384L185 373',p.gold,3),
    gradient('face',dark?'#332B24':'#EFE4D2',dark?'#30261F':'#E7D7BD','100%'));
  save('klotski_target',128,128,tile(128,128,'coral',14));
  save('klotski_vertical',80,160,tile(80,160,'gold',10));
  save('klotski_horizontal',160,80,tile(160,80,'wood',10));
  save('klotski_soldier',80,80,tile(80,80,'wood',10));
  save('mole',100,100,ellipse(50,82,35,7,p.edge,.32)+ellipse(50,61,29,25,'url(#wood)')+
    circle(28,31,10,'url(#wood)')+circle(72,31,10,'url(#wood)')+ellipse(50,43,28,24,'url(#wood)')+
    ellipse(50,58,17,10,'#FFE7AD')+circle(39,42,4,'#304A69')+circle(61,42,4,'#304A69')+
    ellipse(50,51,6,4,'#304A69')+ellipse(29,79,10,5,'url(#wood)')+ellipse(71,79,10,5,'url(#wood)'));
  save('whack_hole',128,92,ellipse(64,51,60,32,p.edge)+ellipse(64,49,53,26,'#20364F')+
    line('M14 54Q64 89 114 54',dark?'#516884':'#9CB7D0',7));
  save('mine',100,100,Array.from({length:8},(_,i)=>`<g transform="rotate(${i*45} 50 50)">${line('M50 8V26','#6386A8',7)}</g>`).join('')+
    circle(50,50,29,'url(#ink)',p.edge)+ellipse(41,38,10,5,'#FFFFFF',.5));
  save('flag',100,100,line('M27 15V87',p.ink,5)+shape('M30 17H81L65 43L30 47Z','url(#coral)',p.edge)+line('M14 88H48',p.ink,5));
  save('memory_back',100,120,tile(100,120,'blue',14)+rect(11,10,78,97,9,'none','#DCE8F1',2)+
    shape('M50 27L59 48L81 50L65 64L71 86L50 74L29 86L35 64L19 50L41 48Z','url(#gold)'));
  const motifs = [
    ['sun',circle(50,50,21,'url(#gold)')+line('M50 12V23M50 77V88M12 50H23M77 50H88M23 23L31 31M69 69L77 77M77 23L69 31M31 69L23 77',p.gold,5)],
    ['moon',shape('M68 18A31 31 0 1 0 82 71A33 33 0 0 1 68 18Z','url(#violet)')],
    ['star',shape('M50 15L60 38L85 40L66 57L72 82L50 68L28 82L34 57L15 40L40 38Z','url(#gold)')],
    ['heart',shape('M50 80L20 52C1 32 21 12 40 27L50 37L60 27C79 12 99 32 80 52Z','url(#coral)')],
    ['clover',[38,62].map(x=>[38,62].map(y=>circle(x,y,15,'url(#mint)')).join('')).join('')],
    ['bolt',shape('M56 14L26 54H46L40 87L75 42H54Z','url(#blue)')],
    ['crown',shape('M20 35L34 48L50 22L66 48L80 35L74 76H26Z','url(#gold)')],
    ['diamond',shape('M50 13L83 50L50 87L17 50Z','url(#cyan)',p.edge)+line('M50 13V87M17 50H83','#FFFFFF',2,.6)],
    ['spiral',line('M65 44C60 33 40 36 40 50C40 63 63 67 74 54C89 35 70 13 48 14C20 16 8 49 25 71C42 93 78 88 88 63',p.violet,9)],
    ['leaf',shape('M21 75C19 40 43 19 82 18C84 57 62 83 28 80Z','url(#mint)')+line('M25 76L74 28','#4D9E85',4)],
    ['shell',shape('M18 69C17 40 31 20 50 20S83 40 82 69Z','url(#coral)')+line('M50 22V68M33 29L40 68M67 29L60 68','#CF645F',3)],
    ['flame',shape('M51 13C60 32 35 39 38 56C27 48 27 38 29 32C14 50 25 84 50 86C77 84 87 56 69 40C68 55 56 56 60 42C63 33 58 22 51 13Z','url(#gold)')]
  ];
  for (const [name,body] of motifs) save('memory_'+name,100,100,circle(50,50,45,p.low)+body);
  save('jump_frog',100,100,ellipse(50,52,29,22,'url(#mint)')+circle(33,31,12,'url(#mint)')+circle(67,31,12,'url(#mint)')+
    circle(33,31,7,'#FFFAF0')+circle(67,31,7,'#FFFAF0')+circle(35,33,3,'#304A69')+circle(69,33,3,'#304A69')+
    ellipse(50,61,21,12,'#C7EDD0')+line('M40 63Q50 71 61 63','#304A69',2)+ellipse(21,73,16,7,'url(#mint)')+ellipse(79,73,16,7,'url(#mint)'));
  save('jump_platform',160,52,tile(160,52,'wood',13));
  save('brick_gloss',160,64,gloss(160,64,10));
  save('brick_paddle',160,32,tile(160,32,'blue',12));
  save('brick_ball',64,64,circle(32,33,27,p.edge)+
    circle(32,30,27,'url(#ivory)',dark?'#ABC5DA':'#35516B',4)+ellipse(24,21,9,5,'#FFFFFF',.65));
  const outlines = [
    'M27 10H73L96 50L73 90H27L4 50Z',
    'M50 4L93 50L50 96L7 50Z',
    'M12 83C4 45 31 10 91 10C94 61 65 96 22 88Z',
    'M50 4C39 23 17 47 17 65A33 33 0 0 0 83 65C83 47 61 23 50 4Z',
    'M50 90L15 56C-8 30 17 2 40 15L50 23L60 15C84 2 108 30 85 56Z',
    'M50 4L63 34L96 38L71 61L78 94L50 77L22 94L29 61L4 38L37 34Z'
  ];
  const facets = [
    'M14 50L31 18H68', 'M18 50L50 15L81 49', 'M24 76Q43 49 76 25M44 53L43 37',
    'M31 71Q23 58 39 38', 'M17 34Q19 20 31 22', 'M50 18L58 40L77 42'
  ];
  const gemColors = ['cyan','gold','mint','blue','coral','violet'];
  for (let i=0;i<6;i++) save('gem_'+i,100,100,shape(outlines[i],`url(#${gemColors[i]})`,p.ink,2.5)+
    line(facets[i],'#FFFFFF',4,.75));
  save('jump_scene',400,500,rect(0,0,400,500,24,'url(#paper)')+
    shape('M0 449Q100 409 211 458Q315 417 400 442V500H0Z',dark?'#263F3A':'#D1E5DB')+
    ellipse(74,81,50,15,p.paper,.6)+ellipse(287,125,67,17,p.paper,.45));

  const gardenEdge = dark?'#365347':'#95B998';
  const snakeChecks = Array.from({length:20},(_,row)=>`M${row%2*20} ${10+row*20}H400`).join('');
  save('snake_board',400,400,rect(0,0,400,400,0,'url(#face)')+
    `<path d="${snakeChecks}" fill="none" stroke="${dark?'#739884':'#85A98A'}" stroke-width="20" stroke-dasharray="20 20" opacity="${dark?.105:.13}"/>`+
    line('M1 25V1H25M375 1H399V25M1 375V399H25M399 375V399H375',gardenEdge,4)+
    line('M3 32V368M397 32V368',gardenEdge,2,.5)+
    line('M4 92Q10 76 20 68M4 80Q13 82 17 76M396 308Q390 323 380 332M396 319Q387 317 383 324',gardenEdge,2,.65),
  gradient('face',dark?'#253C32':'#F4F8EE',dark?'#1B2B25':'#DEEADB'));

  const enamelEdge = dark?'#506889':'#9DB7CD';
  save('tetris_board',220,440,surface(220,440,enamelEdge,10)+
    line('M14 18V11H43M177 11H206V18M14 422V429H43M177 429H206V422',p.ink,2,.32)+
    line('M13 37V403M207 37V403',p.white,1.5,dark?.11:.40),
  gradient('face',dark?'#2C4058':'#E8F1F8',dark?'#1F2B42':'#CCDDED'));

  save('2048_board',400,400,surface(400,400,dark?'#5A6D82':'#A0B6C7')+
    line('M16 28V16H28M372 16H384V28M16 372V384H28M384 372V384H372',p.white,2,dark?.23:.58),
  gradient('face',dark?'#3E526A':'#C8D9E4',dark?'#304158':'#A9C0D3'));
  save('2048_well',100,100,rect(0,0,100,100,14,'url(#face)')+
    rect(1,1,98,98,13,'none',p.edge,2)+line('M17 7Q8 7 8 18V69',p.ink,2,.17)+
    line('M92 20V82Q92 92 82 92H27',p.white,2,dark?.16:.64),
  gradient('face',dark?'#26384D':'#D7E3EA',dark?'#344D65':'#EEF4F7'));

  save('mine_board',400,400,surface(400,400,dark?'#6A8095':'#839BAF',13)+
    line('M21 7H379M7 22V378',p.white,2,dark?.14:.56),
  gradient('face',dark?'#405669':'#CEDCE7',dark?'#304454':'#AFC0CD'));
  save('mine_cover',100,100,rect(3,3,94,94,13,'url(#face)',p.edge,2)+
    line('M14 32V20Q14 14 20 14H69',p.white,3,dark?.19:.63)+
    line('M83 73V84H65',p.ink,2,.22),
  gradient('face',dark?'#3D556D':'#E6EFF5',dark?'#293D50':'#B9CCD9'));

  const sudokuRooms = [0,1,2].flatMap(row=>[0,1,2].filter(col=>(row+col)%2===1)
    .map(col=>rect(col*132+2,row*132+2,132,132,0,dark?'#27374A':'#EDF3F3'))).join('');
  save('sudoku_board',400,400,rect(0,0,400,400,4,'url(#face)')+sudokuRooms+
    line('M4 395H396M396 5V395',p.edge,2,.46),
  gradient('face',dark?'#30445C':'#FFFBF1',dark?'#293B51':'#F3EEE2'));

  save('slide_board',400,400,surface(400,400,dark?'#526F65':'#8CAB9C')+
    [42,109,197,275,352].map(y=>line(`M10 ${y}Q101 ${y-6} 208 ${y}T390 ${y}`,dark?'#7EABA0':'#648B7E',1,.33)).join('')+
    line('M16 29V18H29M371 18H384V29M16 371V383H29M371 383H384V371',p.white,2,dark?.24:.58),
  gradient('face',dark?'#3B5751':'#CCDFD3',dark?'#29403D':'#AACBBE'));

  const keypadTint = dark?'#31475F':'#CDDFEA';
  const keypadFade = `<radialGradient id="keypad" cx="50%" cy="46%" r="53%">
    <stop stop-color="${keypadTint}" stop-opacity=".68"/>
    <stop offset="58%" stop-color="${keypadTint}" stop-opacity=".43"/>
    <stop offset="100%" stop-color="${keypadTint}" stop-opacity="0"/>
  </radialGradient>`;
  save('guess_panel',160,136,rect(0,0,160,136,0,'url(#keypad)'),keypadFade);

  save('memory_board',400,500,surface(400,500,dark?'#45556E':'#A7B9CD',24)+
    rect(12,12,376,476,16,'none',p.edge,2)+
    line('M15 54Q24 35 54 22M346 22Q376 35 385 54M15 446Q24 465 54 478M346 478Q376 465 385 446',p.white,2,dark?.17:.56)+
    line('M29 30H54M29 30V56M371 30H346M371 30V56M29 470H54M29 470V444M371 470H346M371 470V444',p.edge,2,.55),
  gradient('face',dark?'#30445B':'#DAE7EF',dark?'#252E46':'#C6D6E7'));

  const meadow = dark?'#3C6050':'#A2C489';
  const shrub = dark?'#324A36':'#AFCC96';
  const shrubLit = dark?'#3C593E':'#C0D9A7';
  const fence = dark?'#625D43':'#C2AB70';
  const pebble = dark?'#646854':'#ABBD99';
  save('whack_scene',400,400,surface(400,400,gardenEdge,19)+
    shape('M4 365Q10 354 25 358Q35 347 48 356Q61 357 66 374Q80 371 89 386L93 396H23Q4 396 4 377Z',shrub)+
    shape('M396 24V65Q381 65 372 54Q357 58 352 42Q335 40 332 23Q322 16 322 4H376Q396 4 396 24Z',shrub)+
    shape('M6 370Q24 361 35 368Q46 362 54 375Q65 373 70 383Q52 380 41 389H12Z',shrubLit)+
    shape('M396 30Q385 47 374 42Q365 44 360 34Q346 36 343 24Q331 20 331 7H374Q394 7 396 30Z',shrubLit)+
    line('M28 26H78M28 33H78',fence,3,.62)+[28,45,62,78].map(x=>rect(x-2,20,4,19,1.5,fence)).join('')+
    ellipse(109,24,5,2.4,pebble,.65)+ellipse(119,22,3,1.5,pebble,.58)+
    ellipse(340,377,6,2.5,pebble,.64)+ellipse(351,382,3.5,1.5,pebble,.52)+
    line('M18 80l4-10 5 10M377 102l5-10 4 10M16 263l5-11 5 11M367 356l4-9 5 9',meadow,2),
  gradient('face',dark?'#263529':'#DCECD0',dark?'#1C2920':'#C4DFB2','100%'));

  const courtEdge = dark?'#6B8FA9':'#779BB3';
  save('brick_scene',400,500,surface(400,500,courtEdge,17)+
    rect(8,8,384,484,12,'none',p.edge,2)+
    line('M12 468V33Q12 15 33 15H367Q388 15 388 33V468',p.white,2,dark?.16:.58)+
    line('M16 128V72M16 221V165M16 314V258M16 407V351M384 72V128M384 165V221M384 258V314M384 351V407',courtEdge,2,.45)+
    line('M28 470H65M334 470H372',courtEdge,2,.48),
  gradient('face',dark?'#233A50':'#EAF2F6',dark?'#19283E':'#CDDFEB'));

  const jewelRim = dark?'#50697F':'#8AABBC';
  save('match3_board',400,400,surface(400,400,jewelRim,20)+
    line('M12 28V12H28M372 12H388V28M12 372V388H28M372 388H388V372',p.white,2,dark?.21:.67),
  gradient('face',dark?'#40566C':'#C3D6DC',dark?'#303F52':'#99B8C5'));
  save('match3_well',100,100,rect(0,0,100,100,15,'url(#face)')+
    line('M9 46V19Q9 9 19 9H46',p.edge,2,.46)+line('M55 91H81Q91 91 91 81V55',p.white,2,dark?.14:.58),
  gradient('face',dark?'#2A3B50':'#E3EDF0',dark?'#384F64':'#F4F8F6'));
}
for (const name of selected) {
  if (!generated.some(asset=>asset.name==='play_'+name)) throw new Error('Unknown original-game resource: '+name);
}
await Promise.all(rasterJobs);
fs.writeFileSync(path.join(root,'docs/art/legacy-gameplay-manifest.json'),JSON.stringify({
  style:'Shared icon palette; soft vector toy materials; base and dark', games:13, assets:generated
},null,2)+'\n');
console.log(`Generated ${selected.size || generated.length} original-game resources in both themes.`);
