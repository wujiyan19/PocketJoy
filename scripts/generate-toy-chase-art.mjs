/** Original, texture-free toy geometry. Only generates the blackhole/drift assets. */
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { fileURLToPath } from 'node:url';
import * as T from '../.local-tools/toy-art/node_modules/three/build/three.module.js';
import { RoundedBoxGeometry } from '../.local-tools/toy-art/node_modules/three/examples/jsm/geometries/RoundedBoxGeometry.js';
import { chromium } from '../.local-tools/toy-art/node_modules/playwright-core/index.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const raw=path.join(root,'entry/src/main/resources/rawfile/toy'),media=path.join(root,'entry/src/main/resources/base/media');
const docs=path.join(root,'docs/art/toy/chase');fs.mkdirSync(docs,{recursive:true});
const palette=['#EC947F','#E7BE6F','#83BCA5','#8DB8D0','#ADA0C7','#C4A17F'];
const geometries=new Map(),assets=[],jobs=[];const light=new T.Vector3(-.45,.65,1).normalize();
const group=name=>{const g=new T.Group();g.name=name;return g;};
function geom(key,make){if(!geometries.has(key))geometries.set(key,make());return geometries.get(key);}
function mesh(g,geometry,color,x=0,y=0,z=0){const m=new T.Mesh(geometry,new T.MeshBasicMaterial({color}));m.position.set(x,y,z);g.add(m);return m;}
function box(g,w,h,d,color,x=0,y=0,z=0){return mesh(g,geom([w,h,d].join(','),()=>new RoundedBoxGeometry(w,h,d,2,Math.min(3,w/5,h/5,d/5))),color,x,y,z);}
function disk(g,r,color,z=0){const m=mesh(g,geom('disk'+r,()=>new T.CylinderGeometry(r,r,1,24)),color,0,0,z);m.rotation.x=Math.PI/2;return m;}
function ring(g,r,t,color,z=0){return mesh(g,geom('ring'+r+','+t,()=>new T.TorusGeometry(r,t,5,24)),color,0,0,z);}
function prop(index){
  const g=group('prop'+index),color=palette[index%6];
  if(index%6===0){mesh(g,geom('ball',()=>new T.SphereGeometry(13,16,10)),color,0,0,14);box(g,4,22,2,'#FFF1D2',0,0,25);}
  else if(index%6===1){box(g,22,22,22,color,0,0,12);box(g,14,14,2,'#F6E6BE',0,0,24);}
  else if(index%6===2){box(g,23,23,4,'#E8D6AF',0,0,3);const m=mesh(g,geom('cone',()=>new T.ConeGeometry(12,27,20)),color,0,0,17);m.rotation.x=Math.PI/2;ring(g,7,2,'#FFF1D2',19);}
  else if(index%6===3){const m=mesh(g,geom('barrel',()=>new T.CylinderGeometry(11,12,25,20)),color,0,0,14);m.rotation.x=Math.PI/2;ring(g,10,1.4,'#F3DFAE',27);}
  else if(index%6===4){box(g,22,23,18,color,0,0,10);const roof=box(g,22,24,4,'#E7BE6F',0,0,22);roof.rotation.y=.35;box(g,8,2,10,'#526976',0,-12,9);}
  else{box(g,24,24,10,color,0,0,6);box(g,18,18,13,'#EC947F',0,0,18);box(g,4,20,2,'#F8E9C7',0,0,25);}
  g.rotation.set(.22,.14,0);return g;
}
function blackhole(dark){
  const g=group('world');box(g,358,458,12,'#B99D78',0,0,-11);box(g,346,446,8,dark?'#3F5360':'#ECE3CF',0,0,-5);
  // Sparse floor inlays help show movement without adding a large texture.
  for(let y=-184;y<=184;y+=92)for(let x=-138;x<=138;x+=92)diskAt(g,x,y,dark?'#536571':'#D5C9AD');
  for(let i=0;i<55;i++){
    const shadow=group('shadow'+i);disk(shadow,15,dark?'#2A3E47':'#B6B399',.15);g.add(shadow);
    const edible=group('edible'+i);ring(edible,16,1.4,'#8FCFA0',.7);g.add(edible);g.add(prop(i));
  }
  const hole=group('hole');disk(hole,20,'#A6A58A',.9);disk(hole,19,'#273B46',1.5);disk(hole,16,'#101F29',2.2);
  ring(hole,19,1.4,'#72A9AB',2.4);g.add(hole);return g;
}
function diskAt(g,x,y,color){const d=group('inlay');disk(d,1.5,color,.05);d.position.set(x,y,0);g.add(d);}
function coupe(){
  const g=group('coupe');
  for(const x of [-13,13])for(const y of [-22,21])box(g,7,14,9,'#3F505A',x,y,3);
  box(g,29,63,12,palette[0],0,0,8);box(g,24,28,12,palette[0],0,-4,18);
  box(g,22,10,2,'#395C71',0,12,23);box(g,21,8,2,'#395C71',0,-19,19);
  box(g,6,16,2,'#FFF0CF',0,25,15);box(g,6,12,2,'#FFF0CF',0,-27,15);
  for(const x of [-9,9]){box(g,6,3,2,'#FFF1C4',x,29,15);box(g,6,2,2,'#C25850',x,-30,14);}
  return g;
}
function serialized(g){const copy=g.clone(true);copy.traverse(m=>{if(m.isMesh)m.geometry=new T.BufferGeometry().copy(m.geometry);});copy.updateMatrixWorld(true);return copy.toJSON();}
function glb(g,name){
  const j={asset:{version:'2.0',generator:'LittleGames original toy chase geometry'},scene:0,scenes:[{nodes:[]}],nodes:[],meshes:[],materials:[{pbrMetallicRoughness:{baseColorFactor:[1,1,1,1],metallicFactor:0,roughnessFactor:.85},extensions:{KHR_materials_unlit:{}}}],extensionsUsed:['KHR_materials_unlit'],accessors:[],bufferViews:[],buffers:[],cameras:[{type:'orthographic',orthographic:{xmag:180,ymag:230,znear:.1,zfar:3000}}]};
  const chunks=[],cache=new Map();let size=0;
  function acc(a,type,componentType,min,max){const b=Buffer.from(a.buffer,a.byteOffset,a.byteLength),pad=Buffer.alloc(Math.ceil(b.length/4)*4);b.copy(pad);const view=j.bufferViews.length;j.bufferViews.push({buffer:0,byteOffset:size,byteLength:b.length});chunks.push(pad);size+=pad.length;const id=j.accessors.length;j.accessors.push({bufferView:view,componentType,count:a.length/(type==='SCALAR'?1:3),type,...(min?{min,max}:{})});return id;}
  function visit(o){const n={name:o.name||'part',translation:o.position.toArray(),rotation:o.quaternion.toArray(),scale:o.scale.toArray()},id=j.nodes.length;j.nodes.push(n);
    if(o.isMesh){const key=o.geometry.uuid+o.material.color.getHexString();let mi=cache.get(key);if(mi===undefined){const p=o.geometry.attributes.position,normal=o.geometry.attributes.normal,c=new Float32Array(p.count*3),bounds=new T.Box3().setFromBufferAttribute(p);
      for(let i=0;i<p.count;i++){const v=o.material.color.clone().multiplyScalar(.76+.24*Math.max(0,new T.Vector3().fromBufferAttribute(normal,i).dot(light)));c.set([v.r,v.g,v.b],i*3);}
      const primitive={attributes:{POSITION:acc(new Float32Array(p.array),'VEC3',5126,bounds.min.toArray(),bounds.max.toArray()),NORMAL:acc(new Float32Array(normal.array),'VEC3',5126),COLOR_0:acc(c,'VEC3',5126)},material:0};if(o.geometry.index)primitive.indices=acc(new Uint16Array(o.geometry.index.array),'SCALAR',5123);mi=j.meshes.length;j.meshes.push({primitives:[primitive]});cache.set(key,mi);}n.mesh=mi;}
    if(o.children.length)n.children=o.children.map(visit);return id;}
  j.scenes[0].nodes.push(visit(g));j.nodes.push({name:'ToyCamera',camera:0,translation:[0,0,1000]});j.scenes[0].nodes.push(j.nodes.length-1);j.buffers.push({byteLength:size});
  const bytes=Buffer.from(JSON.stringify(j)),json=Buffer.alloc(Math.ceil(bytes.length/4)*4,32);bytes.copy(json);const bin=Buffer.concat(chunks),header=Buffer.alloc(12),jh=Buffer.alloc(8),bh=Buffer.alloc(8);
  header.writeUInt32LE(0x46546c67);header.writeUInt32LE(2,4);header.writeUInt32LE(28+json.length+bin.length,8);jh.writeUInt32LE(json.length);jh.writeUInt32LE(0x4e4f534a,4);bh.writeUInt32LE(bin.length);bh.writeUInt32LE(0x004e4942,4);
  const out=path.join(raw,name+'.glb');fs.writeFileSync(out,Buffer.concat([header,jh,json,bh,bin]));assets.push({name:'toy/'+name+'.glb',bytes:fs.statSync(out).size,packaged:true,meshes:j.meshes.length,nodes:j.nodes.length});
}
for(const dark of [false,true]){
  const g=blackhole(dark);glb(g,dark?'blackhole_dark':'blackhole');
  for(let i=0;i<55;i++){const x=-140+i%7*46,y=182-Math.floor(i/7)*52,r=(8+Math.floor(i/8)*4)/16;for(const prefix of ['prop','shadow','edible']){const n=g.getObjectByName(prefix+i);n.position.set(x,y,0);n.scale.set(r,r,r);}}
  const h=g.getObjectByName('hole');h.position.set(0,0,0);jobs.push({object:serialized(g),name:dark?'blackhole_preview_dark':'blackhole_preview',bounds:[-180,180,230,-230],w:720,h:920,preview:true});
}
jobs.push({object:serialized(coupe()),name:'toy_drift_car',bounds:[-22,22,40,-40],w:176,h:320,preview:false});
const server=http.createServer((req,res)=>{if(req.url==='/'){res.end('<html><body style="margin:0"></body></html>');return;}const p=path.resolve(root,'.'+decodeURIComponent(req.url));if(!p.startsWith(path.join(root,'.local-tools/toy-art/node_modules')+path.sep)||!fs.existsSync(p)){res.writeHead(404);res.end();return;}res.setHeader('Content-Type','text/javascript');res.end(fs.readFileSync(p));});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const url='http://127.0.0.1:'+server.address().port;
const browser=await chromium.launch({executablePath:process.env.TOY_ART_BROWSER||'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
try{const page=await browser.newPage();await page.goto(url);await page.evaluate(async url=>{window.T=await import(url);},url+'/.local-tools/toy-art/node_modules/three/build/three.module.js');
  for(const job of jobs){await page.setViewportSize({width:job.w,height:job.h});await page.evaluate(job=>{const T=window.T;window.renderer?.dispose();document.body.innerHTML='';const r=new T.WebGLRenderer({alpha:true,antialias:true,preserveDrawingBuffer:true});window.renderer=r;r.setClearColor(0,0);r.setSize(job.w,job.h);document.body.append(r.domElement);const g=new T.ObjectLoader().parse(job.object),light=new T.Vector3(-.45,.65,1).normalize();g.traverse(m=>{if(!m.isMesh)return;const geo=m.geometry.clone(),n=geo.attributes.normal,c=new Float32Array(n.count*3);for(let i=0;i<n.count;i++){const col=m.material.color.clone().multiplyScalar(.76+.24*Math.max(0,new T.Vector3().fromBufferAttribute(n,i).dot(light)));c.set([col.r,col.g,col.b],i*3);}geo.setAttribute('color',new T.BufferAttribute(c,3));m.geometry=geo;m.material=new T.MeshBasicMaterial({vertexColors:true});});const scene=new T.Scene();scene.add(g);const camera=new T.OrthographicCamera(...job.bounds,.1,3000);camera.position.z=1000;r.render(scene,camera);},job);
    const out=path.join(job.preview?docs:media,job.name+'.png');await page.locator('canvas').screenshot({path:out,omitBackground:true});assets.push({name:job.name+'.png',bytes:fs.statSync(out).size,packaged:!job.preview});}
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
fs.writeFileSync(path.join(docs,'manifest.json'),JSON.stringify({originalGeometry:true,noRuntimeBrowserOrThreeJS:true,assets,totalBytes:assets.filter(a=>a.packaged).reduce((sum,a)=>sum+a.bytes,0)},null,2)+'\n');console.log(JSON.stringify(assets.map(a=>({name:a.name,bytes:a.bytes}))));
