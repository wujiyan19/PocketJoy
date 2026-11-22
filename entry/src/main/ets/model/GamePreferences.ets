import { Context } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const FLUSH_DELAY_MS: number = 200;

/** The owner supplies its current snapshot. This class owns only Preferences I/O. */
export class GamePreferences {
  private store: preferences.Preferences | null = null;
  private unreadKeys: Set<string> = new Set<string>();
  private timer: number = -1;
  private dirty: boolean = false;
  private pendingFlushes: number = 0;
  private writeSnapshot: () => void;

  constructor(writeSnapshot: () => void) { this.writeSnapshot = writeSnapshot; }

  open(context: Context, name: string): boolean {
    this.unreadKeys.clear();
    try {
      this.store = preferences.getPreferencesSync(context, { name: name });
      return true;
    } catch (e) {
      this.store = null;
      hilog.error(0x0000, 'LittleGames', 'Failed to open game preferences');
      return false;
    }
  }

  read(key: string): string {
    if (!this.store) { return ''; }
    try {
      const value = this.store.getSync(key, '');
      return typeof value === 'string' ? value : '';
    } catch (e) {
      this.unreadKeys.add(key);
      hilog.error(0x0000, 'LittleGames', 'Failed to read preferences key %{public}s; original value retained', key);
      return '';
    }
  }

  write(key: string, value: string): void {
    if (this.store && !this.unreadKeys.has(key)) { this.store.putSync(key, value); }
  }

  /** An explicit reset may replace a value we could not read at startup. */
  allowOverwrite(key: string): void { this.unreadKeys.delete(key); }

  schedule(): void {
    this.dirty = true;
    if (!this.store) { return; }
    if (this.timer !== -1) { clearTimeout(this.timer); }
    this.timer = setTimeout(() => {
      this.timer = -1;
      this.persist(false);
    }, FLUSH_DELAY_MS);
  }

  flushNow(changed: boolean = false): void {
    if (changed) { this.dirty = true; }
    if (this.timer !== -1) { clearTimeout(this.timer); this.timer = -1; }
    this.persist(true);
  }

  private persist(sync: boolean): void {
    if (!this.store || (!this.dirty && (!sync || this.pendingFlushes === 0))) { return; }
    try {
      if (this.dirty) {
        this.writeSnapshot();
        this.dirty = false;
      }
      if (sync) {
        this.store.flushSync();
      } else {
        const flush = this.store.flush();
        this.pendingFlushes++;
        flush.then(() => { this.pendingFlushes--; }).catch((err: BusinessError) => {
          this.pendingFlushes--;
          this.dirty = true;
          hilog.error(0x0000, 'LittleGames', 'Failed to flush preferences: %{public}d', err.code);
        });
      }
    } catch (e) {
      this.dirty = true;
      hilog.error(0x0000, 'LittleGames', 'Failed to persist game data');
    }
  }
}
