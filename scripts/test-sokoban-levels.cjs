const assert = require('node:assert/strict');

// In move mode every edge costs one. In push mode walks stay in this
// distance layer and pushes enter the next layer (0–1 breadth-first search).
function solve(rows, countPushes = false, { freezeParked = false, boxMayEnterArrow = true } = {}) {
  const width = rows[0].length;
  const tiles = rows.join('');
  const offsets = [-width, 1, width, -1];
  const arrows = '^>v<';
  const initialBoxes = [];
  for (let i = 0; i < tiles.length; i++) {
    if (tiles[i] === '$') initialBoxes.push(i);
  }
  const start = { player: tiles.indexOf('@'), boxes: initialBoxes, marked: tiles.indexOf('A'), route: '' };
  const visited = new Set();
  let frontier = [start];
  for (let distance = 0; frontier.length; distance++) {
    const nextFrontier = [];
    for (let i = 0; i < frontier.length; i++) {
      const { player, boxes, marked, route } = frontier[i];
      const key = `${player}/${marked}/${boxes.join(',')}`;
      if (visited.has(key)) continue;
      visited.add(key);
      if (boxes.every(cell => tiles[cell] === '.') && (marked < 0 || tiles[marked] === 'a')) {
        return { distance, route };
      }
      for (let direction = 0; direction < 4; direction++) {
        const dest = player + offsets[direction];
        if (tiles[dest] === '#' || (arrows.includes(tiles[dest]) && tiles[dest] !== arrows[direction])) continue;
        const boxIndex = boxes.indexOf(dest);
        const push = boxIndex >= 0 || dest === marked;
        let nextBoxes = boxes;
        let nextMarked = marked;
        if (push) {
          if (freezeParked && (tiles[dest] === '.' || tiles[dest] === 'a')) continue;
          const beyond = dest + offsets[direction];
          if (tiles[beyond] === '#' || boxes.includes(beyond) || beyond === marked ||
              (arrows.includes(tiles[beyond]) && (!boxMayEnterArrow || tiles[beyond] !== arrows[direction]))) continue;
          if (dest === marked) {
            nextMarked = beyond;
          } else {
            nextBoxes = boxes.slice();
            nextBoxes[boxIndex] = beyond;
            nextBoxes.sort((a, b) => a - b);
          }
        }
        const state = { player: dest, boxes: nextBoxes, marked: nextMarked, route: route + direction };
        if (countPushes && !push) frontier.push(state);
        else nextFrontier.push(state);
      }
    }
    frontier = nextFrontier;
  }
  return undefined;
}

function shortestRoute(rows) {
  const result = solve(rows);
  assert.ok(result, 'The board has no solution');
  return Array.from(result.route, Number);
}

if (require.main === module) {
  const { fixture } = require('./test-performance.cjs');
  const { SOKOBAN_LEVELS } = fixture().load('entry/src/main/ets/model/game/SokobanLevels.ets');
  assert.equal(SOKOBAN_LEVELS.length, 12);
  for (const [index, level] of SOKOBAN_LEVELS.entries()) {
    const { rows, minPushes, minMoves } = level;
    const cells = rows.join('');
    const count = symbol => Array.from(cells).filter(cell => cell === symbol).length;
    assert.equal(rows.length, 7);
    assert.equal(rows[0], '#######');
    assert.equal(rows[6], '#######');
    for (const row of rows) assert.match(row, /^#[# @$.Aa<>^v]{5}#$/);
    assert.equal(count('@'), 1);
    assert.ok(count('$') > 0);
    assert.equal(count('$'), count('.'));
    assert.equal(count('A'), index >= 8 ? 1 : 0);
    assert.equal(count('A'), count('a'));
    assert.equal(/[<>^v]/.test(cells), (index >= 4 && index <= 7) || index >= 10);

    assert.equal(shortestRoute(rows).length, minMoves, `level ${index + 1} minimum moves`);
    assert.equal(solve(rows, true).distance, minPushes, `level ${index + 1} minimum pushes`);
    if (index > 0) {
      assert.ok(minPushes > SOKOBAN_LEVELS[index - 1].minPushes);
      assert.ok(minMoves > SOKOBAN_LEVELS[index - 1].minMoves);
    }
    // Removing each mechanism in isolation must unlock a strictly shorter route.
    if (/[<>^v]/.test(cells)) {
      assert.ok(solve(rows.map(row => row.replace(/[<>^v]/g, ' '))).distance < minMoves);
      assert.equal(solve(rows.map(row => row.replace(/[<>^v]/g, '#'))), undefined,
        'players must use the one-way tiles to finish');
      if ([7, 8, 11].includes(index + 1)) {
        assert.equal(solve(rows, false, { boxMayEnterArrow: false }), undefined,
          'walking through the arrow alone is insufficient: a box must cross it too');
      }
    }
    if (cells.includes('A')) {
      assert.ok(solve(rows.map(row => row.replace('A', '$').replace('a', '.'))).distance < minMoves);
    }
    console.log(`Level ${index + 1}: minimum pushes ${minPushes}, minimum moves ${minMoves}`);
  }
  const opening = SOKOBAN_LEVELS[0].rows;
  assert.equal(opening.join('').split('$').length - 1, 2);
  assert.equal(solve(opening, false, { freezeParked: true }), undefined,
    'the first box to reach a goal must move again to leave room for the second');
  // Two steps to the right trap the lower box along a wall with no goals.
  const trapped = opening.map(row => row.replace('@ $ ', '  @$'));
  assert.notDeepEqual(trapped, opening);
  assert.equal(solve(trapped), undefined);
  // The third box in the second level blocks the first level's opening move.
  const sequel = SOKOBAN_LEVELS[1].rows;
  assert.deepEqual(opening.map(row => row.replace(/[^#]/g, ' ')), sequel.map(row => row.replace(/[^#]/g, ' ')));
  const player = opening.join('').indexOf('@');
  assert.equal(sequel.join('').indexOf('@'), player);
  assert.equal(sequel.join('').slice(player + 1, player + 3), '$$');
  assert.ok(SOKOBAN_LEVELS.at(-1).minPushes >= 22 && SOKOBAN_LEVELS.at(-1).minMoves >= 65);
  console.log(`${SOKOBAN_LEVELS.length}/${SOKOBAN_LEVELS.length} level checks passed`);
}

module.exports = { solve, shortestRoute };
