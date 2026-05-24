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

async function readIfExists(p) { try { return await fs.readFile(p, 'utf8'); } catch { return null; } }
function extOf(f) { const b = path.basename(f).toLowerCase(); if (b === 'dockerfile') return 'dockerfile'; const e = path.extname(f).toLowerCase(); return e ? e.slice(1) : ''; }

async function scanRepo(root) {
  root = path.resolve(root);
  const files = await listFiles(root, 5000);
  const languages = {};
  const fileCountsByExt = {};
  let totalLines = 0;

  for (const f of files) {
    const ext = extOf(f) || 'none';
    fileCountsByExt[ext] = (fileCountsByExt[ext] || 0) + 1;
    try {
      const stat = await fs.stat(f);
      if (stat.size > 200 * 1024) continue;
      const content = await fs.readFile(f, 'utf8');
      const lines = content.split(/\r?\n/).length;
      totalLines += lines;
      languages[ext] = (languages[ext] || 0) + lines;
    } catch (e) { /* ignore */ }
  }

  const topFolders = Array.from(new Set(files.map(f => {
    const rel = path.relative(root, f);
    return rel.split(path.sep)[0];
  })) ).slice(0, 20);

  const readme = await (async () => {
    for (const name of ['README.md', 'README.rst', 'README.txt']) {
      const p = path.join(root, name);
      const c = await readIfExists(p);
      if (c) return c;
    }
    return null;
  })();

  const manifestFiles = ['package.json','pyproject.toml','go.mod','Cargo.toml','pom.xml'];
  const manifests = {};
  for (const m of manifestFiles) {
    const p = path.join(root, m);
    const c = await readIfExists(p);
    if (c) manifests[m] = true;
  }

  const ciFiles = files.filter(f => f.includes('.github' + path.sep + 'workflows') || f.includes('.github/workflows')).slice(0, 20);
  const hasDockerfile = files.some(f => path.basename(f).toLowerCase() === 'dockerfile');
  const licensePresent = !!(await readIfExists(path.join(root, 'LICENSE')) || await readIfExists(path.join(root, 'LICENSE.md')));

  const packageManagers = [];
  if (manifests['package.json']) packageManagers.push('npm/yarn');
  if (manifests['pyproject.toml']) packageManagers.push('pyproject');
  if (manifests['go.mod']) packageManagers.push('go');
  if (manifests['Cargo.toml']) packageManagers.push('cargo');

  const dominantLanguage = Object.entries(languages).sort((a,b)=>b[1]-a[1])[0]?.[0] || null;

  return {
    root,
    fileCount: files.length,
    totalLines,
    languages,
    fileCountsByExt,
    topFolders,
    readmeSummary: readme ? readme.split(/\r?\n/).slice(0, 20).join('\n') : null,
    manifests: Object.keys(manifests),
    ciFiles,
    hasDockerfile,
    licensePresent,
    packageManagers,
    dominantLanguage,
  };
}

(async ()=>{
  const target = process.argv[2] || '.';
  try{
    const r = await scanRepo(target);
    console.log(JSON.stringify(r, null, 2));
  } catch (e) { console.error('Scan failed:', e); process.exit(2); }
})();
