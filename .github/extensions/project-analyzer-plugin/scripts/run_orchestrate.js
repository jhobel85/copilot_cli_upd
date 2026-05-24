#!/usr/bin/env node
const fs = require('fs').promises;
const path = require('path');

async function listFiles(root, maxFiles = 5000) {
  const out = [];
  const stack = [root];
  while (stack.length && out.length < maxFiles) {
    const dir = stack.pop();
    let entries;
    try { entries = await fs.readdir(dir, { withFileTypes: true }); }
    catch { continue; }
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (['node_modules', '.git', 'venv', '__pycache__', '.venv'].includes(e.name)) continue;
        stack.push(full);
      } else if (e.isFile()) {
        out.push(full);
        if (out.length >= maxFiles) break;
      }
    }
  }
  return out;
}

(async ()=>{
  const target = process.argv[2] || '.';
  const maxFiles = parseInt(process.argv[3] || '500', 10);
  try{
    const root = path.resolve(target);
    const files = await listFiles(root, Math.min(maxFiles, 5000));
    const sampleSize = Math.min(200, files.length);
    const step = Math.max(1, Math.floor(files.length / sampleSize));
    const sample = files.filter((_,i)=> i % step === 0).slice(0, sampleSize);
    const summary = { sampleCount: sample.length, totalFiles: files.length, topFolders: Array.from(new Set(sample.map(f=> path.relative(root, f).split(path.sep)[0]))).slice(0,10) };
    console.log(JSON.stringify({agent_id: `explore-${Date.now()}`, status: 'completed', summary, sample: sample.slice(0,20)}, null, 2));
  } catch (e) { console.error('Orchestrate failed:', e); process.exit(2); }
})();
