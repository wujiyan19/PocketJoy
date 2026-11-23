/* Drop unreachable gradients only. Geometry and all other XML remain untouched. */
const fs = require('node:fs');
const path = require('node:path');
const { rasterizedExpansionBoards } = require('./board-raster.cjs');
const root = path.resolve(__dirname, '..');
const artworkOnly = new Set([
  'col_gem_blue', 'col_gem_coral', 'col_gem_gold', 'col_gem_mint', 'col_gem_violet', 'col_question_memory',
  'col_memory_board', 'col_question_paper', 'col_question_compare', 'col_question_sequence',
  'col_question_binary', 'col_question_targetsum',
  'expansion_puzzle_scene', 'exp_book', 'exp_brush', 'exp_goal', 'exp_plate', 'exp_screw', 'exp_wall',
  ...rasterizedExpansionBoards,
  'play_tetris_board', 'play_2048_well', 'play_2048_board', 'play_mine_board', 'play_sudoku_board',
  'play_slide_board', 'play_guess_panel', 'play_memory_board', 'play_match3_well', 'play_match3_board',
  'play_jump_frog', 'play_jump_platform', 'play_jump_scene'
]);
function svgPath(theme, name) {
  const directory = artworkOnly.has(name) ? 'docs/art/source-media' : 'entry/src/main/resources';
  return path.join(root, directory, theme, 'media', name + '.svg');
}
function resolveSvg(theme, name) {
  const file = svgPath(theme, name);
  return theme === 'dark' && !fs.existsSync(file) ? svgPath('base', name) : file;
}
function writeThemedSvg(theme, name, contents) {
  const file = svgPath(theme, name);
  if (theme === 'dark' && fs.readFileSync(svgPath('base', name), 'utf8') === contents) {
    fs.rmSync(file, { force: true });
    return;
  }
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, contents);
}
function references(xml) {
  return [...xml.matchAll(/url\(\s*#([^\s)]+)\s*\)|(?:xlink:)?href=["']#([^"']+)["']/g)].map(m => m[1] || m[2]);
}
function pruneSvgDefs(svg) {
  return svg.replace(/<defs>([\s\S]*?)<\/defs>/g, (block, definitions) => {
    const gradients = [...definitions.matchAll(/<linearGradient\b[^>]*\bid=["']([^"']+)["'][^>]*>[\s\S]*?<\/linearGradient>/g)];
    const retained = new Set(references(svg.replace(block, '')));
    const other = definitions.replace(/<linearGradient\b[^>]*>[\s\S]*?<\/linearGradient>/g, '');
    for (const id of references(other)) retained.add(id);
    let changed = true;
    while (changed) {
      changed = false;
      for (const gradient of gradients) if (retained.has(gradient[1])) {
        for (const id of references(gradient[0])) if (!retained.has(id)) { retained.add(id); changed = true; }
      }
    }
    let next = definitions;
    for (const gradient of gradients) if (!retained.has(gradient[1])) next = next.replace(gradient[0], '');
    return '<defs>' + next + '</defs>';
  });
}
module.exports = { pruneSvgDefs, resolveSvg, writeThemedSvg };
if (require.main === module) {
  const root = path.resolve(__dirname, '..');
  const backup = path.join(process.env.TEMP || process.env.TMP || root, 'littlegames-ui-20261019');
  let files = 0, before = 0, after = 0;
  for (const theme of ['base', 'dark']) {
    const dir = path.join(root, 'entry/src/main/resources', theme, 'media');
    for (const name of fs.readdirSync(dir).filter(name => name.endsWith('.svg'))) {
      const file = path.join(dir, name), source = fs.readFileSync(file, 'utf8'), next = pruneSvgDefs(source);
      before += Buffer.byteLength(source); after += Buffer.byteLength(next);
      if (next !== source) {
        const snapshot = path.join(backup, path.relative(root, file));
        fs.mkdirSync(path.dirname(snapshot), { recursive: true });
        if (!fs.existsSync(snapshot)) fs.copyFileSync(file, snapshot);
        fs.writeFileSync(file, next); files++;
      }
    }
  }
  console.log(JSON.stringify({ filesChanged: files, beforeBytes: before, afterBytes: after, savedBytes: before - after }));
}
