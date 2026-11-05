/**
 * 随机源抽象（各游戏 Model 共用）
 *
 * 生产用 RealRandom；测试注入 SeededRandom 以获得确定性、可回放的序列。
 */

export interface RandomSource {
  next(): number;
}

export class RealRandom implements RandomSource {
  next(): number {
    return Math.random();
  }
}

export class SeededRandom implements RandomSource {
  private seed: number;
  private legacy: boolean;

  constructor(seed: number, legacy: boolean = false) {
    this.seed = seed;
    this.legacy = legacy;
  }

  next(): number {
    // imul 保留乘积低位；浮点旧算法仅用于重建已保存的 v1 玩具关卡。
    this.seed = this.legacy ? (this.seed * 1103515245 + 12345) % 2147483648 :
      (Math.imul(this.seed, 1103515245) + 12345) & 0x7fffffff;
    return this.seed / 2147483648;
  }
}
