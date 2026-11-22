/** Published arrays are detached from the mutable rules. Reuse their values until a rule changes them. */
export function sameNumbers(left: number[], right: number[]): boolean {
  return left === right || (left.length === right.length && left.every((value: number, i: number) => value === right[i]));
}

export function snapshotNumbers(source: number[], previous?: number[]): number[] {
  return previous !== undefined && sameNumbers(source, previous) ? previous : source.slice();
}
