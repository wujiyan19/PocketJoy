/* Run desktop suites in isolated Node processes. Native and device checks have separate entry points. */
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { execFile } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const manifest = JSON.parse(fs.readFileSync(path.join(__dirname, 'regression-suites.json'), 'utf8'));
const directory = process.env.LITTLEGAMES_REGRESSION_OUTPUT || path.join(root, '.local-tools', 'regressions');
const cache = path.join(root, '.local-tools', 'regression-transpilation');
const jobs = Number(process.env.LITTLEGAMES_REGRESSION_JOBS || Math.min(4, os.availableParallelism()));
if (!Number.isSafeInteger(jobs) || jobs < 1) throw new Error('LITTLEGAMES_REGRESSION_JOBS must be a positive integer');
fs.mkdirSync(directory, { recursive: true });
fs.mkdirSync(cache, { recursive: true });

function run(script) {
  return new Promise(resolve => {
    execFile(process.execPath, [path.join(__dirname, script + '.cjs')], {
      cwd: root, env: { ...process.env, LITTLEGAMES_REGRESSION_CACHE: cache },
      timeout: 120000, windowsHide: true
    }, (error, stdout, stderr) => {
      const output = stdout + stderr;
      fs.writeFileSync(path.join(directory, script + '.log'), output);
      const counts = output.match(/(\d+)\/(\d+)[^\n]*(?:passed|通过)/i) || output.match(/(?:Passed\s+)?(\d+)[^\n]*checks(?:\s+passed)?/i);
      const passed = counts ? Number(counts[1]) : null;
      const total = counts ? Number(counts[2] || counts[1]) : null;
      console.log(`${error ? 'FAIL' : 'PASS'} ${script}: ${passed ?? '?'}/${total ?? '?'}`);
      if (error) console.error(output.slice(-3000));
      resolve({ script, exitCode: error ? error.code ?? null : 0, passed, total, error: error?.message ?? null });
    });
  });
}

async function main() {
  const startedAt = new Date().toISOString();
  const results = new Array(manifest.suites.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(jobs, manifest.suites.length) }, async () => {
    while (next < manifest.suites.length) {
      const index = next++;
      results[index] = await run(manifest.suites[index]);
    }
  }));
  const complete = results.every(result => result.exitCode === 0);
  const passed = results.reduce((sum, result) => sum + (result.passed || 0), 0);
  const total = results.reduce((sum, result) => sum + (result.total || 0), 0);
  const report = { startedAt, completedAt: new Date().toISOString(), scope: 'Single-player desktop regression; no native/device claims',
    excludedSuites: manifest.excludedSuites, jobs, results, complete, passed, total };
  fs.writeFileSync(path.join(directory, 'verification.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(`${passed}/${total} checks; ${results.length} suites; ${complete ? 'all passed' : 'failures remain'}.`);
  if (!complete) process.exitCode = 1;
}

main().catch(error => { console.error(error); process.exitCode = 1; });
