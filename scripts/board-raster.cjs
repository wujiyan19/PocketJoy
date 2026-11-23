const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');

const rasterizedExpansionBoards = new Set([
  'exp_board_blockfit', 'exp_board_tilestack', 'exp_board_arrowclear', 'exp_board_watersort',
  'exp_board_solitaire', 'exp_board_spider', 'exp_board_freecell', 'exp_board_chess', 'exp_board_xiangqi',
  'exp_board_picturepuzzle', 'exp_board_melody', 'exp_board_buscolor',
]);

// ArkUI can paint PNGs as component backgrounds without measuring a separate Image.
async function writeThemedPng(theme, name, svg) {
  const bundled = path.join(os.homedir(), '.cache', 'codex-runtimes', 'codex-primary-runtime', 'dependencies', 'node');
  const sharp = require(require.resolve('sharp', { paths: [__dirname, bundled] }));
  const output = path.join(__dirname, '..', 'entry', 'src', 'main', 'resources', theme, 'media');
  await fs.mkdir(output, { recursive: true });
  await sharp(Buffer.from(svg)).png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(path.join(output, name + '.png'));
}

module.exports = { rasterizedExpansionBoards, writeThemedPng };
