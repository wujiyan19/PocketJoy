// Keep each accessor's original layout while storing identical geometry only once.
function encodeToyGlb(scene, chunks) {
  const offsets = new Map();
  const uniqueChunks = [];
  let size = 0;
  for (let i = 0; i < chunks.length; i++) {
    const view = scene.bufferViews[i];
    const chunk = chunks[i];
    const key = view.byteLength + ':' + chunk.toString('base64');
    if (!offsets.has(key)) {
      offsets.set(key, size);
      uniqueChunks.push(chunk);
      size += chunk.length;
    }
    view.byteOffset = offsets.get(key);
  }
  scene.buffers = [{ byteLength: size }];
  const json = Buffer.from(JSON.stringify(scene));
  const aligned = Buffer.alloc(Math.ceil(json.length / 4) * 4, 0x20);
  json.copy(aligned);
  const header = Buffer.alloc(20);
  header.write('glTF'); header.writeUInt32LE(2, 4);
  header.writeUInt32LE(28 + aligned.length + size, 8);
  header.writeUInt32LE(aligned.length, 12); header.write('JSON', 16);
  const binaryHeader = Buffer.alloc(8);
  binaryHeader.writeUInt32LE(size); binaryHeader.write('BIN', 4);
  return Buffer.concat([header, aligned, binaryHeader, ...uniqueChunks]);
}
module.exports = { encodeToyGlb };
