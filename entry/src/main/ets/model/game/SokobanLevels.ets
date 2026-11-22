// Maps use standard Sokoban symbols for walls, player, boxes and goals.
// A/a is the marked box and its goal. Arrows constrain the direction of entry.
export interface SokobanLevel {
  rows: string[];
  minPushes: number;
  minMoves: number;
}

export const SOKOBAN_LEVELS: SokobanLevel[] = [
  // Fill the deep goal first. The second board blocks the original approach with a third box.
  { minPushes: 7, minMoves: 17, rows: [
    '#######',
    '#..   #',
    '###$  #',
    '# @ $ #',
    '#     #',
    '#######',
    '#######'
  ] },
  { minPushes: 9, minMoves: 21, rows: [
    '#######',
    '#..   #',
    '###$  #',
    '#.@$$ #',
    '#     #',
    '#######',
    '#######'
  ] },
  { minPushes: 10, minMoves: 26, rows: [
    '#######',
    '#  #  #',
    '#  $$ #',
    '#     #',
    '#.@   #',
    '#.   ##',
    '#######'
  ] },
  { minPushes: 11, minMoves: 28, rows: [
    '#######',
    '#     #',
    '##@$  #',
    '#.  $##',
    '#.    #',
    '## $ .#',
    '#######'
  ] },
  // Route the player through one-way tiles, then move boxes through them.
  { minPushes: 12, minMoves: 32, rows: [
    '#######',
    '# .#  #',
    '#  $@##',
    '#. $> #',
    '# $   #',
    '#.## ##',
    '#######'
  ] },
  { minPushes: 13, minMoves: 38, rows: [
    '#######',
    '#  @###',
    '## $ ##',
    '#^ $  #',
    '# $  .#',
    '##  ..#',
    '#######'
  ] },
  { minPushes: 15, minMoves: 45, rows: [
    '#######',
    '#     #',
    '# $@ .#',
    '# $ ^ #',
    '### $.#',
    '###  .#',
    '#######'
  ] },
  { minPushes: 16, minMoves: 53, rows: [
    '#######',
    '#     #',
    '# $  ##',
    '#$ ^ <#',
    '# #$ .#',
    '#. @ .#',
    '#######'
  ] },
  // Stage boxes around the marked pair and combine this with one-way routing.
  { minPushes: 18, minMoves: 58, rows: [
    '#######',
    '#     #',
    '#  $@ #',
    '#  $  #',
    '###A ##',
    '#.a . #',
    '#######'
  ] },
  { minPushes: 19, minMoves: 65, rows: [
    '#######',
    '#   $.#',
    '#  A  #',
    '## $#@#',
    '#  . ##',
    '#. $ a#',
    '#######'
  ] },
  { minPushes: 22, minMoves: 72, rows: [
    '#######',
    '#a@.$.#',
    '#v$ $ #',
    '# A   #',
    '# v#  #',
    '#  .###',
    '#######'
  ] },
  { minPushes: 25, minMoves: 89, rows: [
    '#######',
    '#a .$.#',
    '#.< $@#',
    '# A#  #',
    '# $   #',
    '#   # #',
    '#######'
  ] }
];
