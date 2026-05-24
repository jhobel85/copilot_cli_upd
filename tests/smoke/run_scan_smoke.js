const { spawnSync } = require('child_process');
const path = require('path');

const script = path.join(__dirname, '..', '..', '.github', 'extensions', 'project-analyzer-plugin', 'scripts', 'run_scan.js');
const res = spawnSync('node', [script, path.resolve('.')], { encoding: 'utf8' });
if (res.error) {
  console.error('Failed to run scan script', res.error);
  process.exit(2);
}
try {
  const out = JSON.parse(res.stdout);
  if (typeof out.fileCount === 'number') {
    console.log('Smoke test passed');
    process.exit(0);
  }
  console.error('Unexpected output', res.stdout);
  process.exit(3);
} catch (e) {
  console.error('Invalid JSON output', e, res.stdout);
  process.exit(4);
}
