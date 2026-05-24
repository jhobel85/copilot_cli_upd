// Extension: project-analyzer-plugin
// Plugin providing autonomous agents (as .md files) to scan and analyze any repository.

import { joinSession } from "@github/copilot-sdk/extension";
import fs from "fs/promises";
import path from "path";

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

async function scanRepoHandler(args = {}) {
  const repoPath = args.path || '.';
  const root = path.resolve(repoPath);
  const files = await listFiles(root, 5000);
  const languages = {};
  const fileCountsByExt = {};
  let totalLines = 0;

  for (const f of files) {
    const ext = extOf(f) || 'none';
    fileCountsByExt[ext] = (fileCountsByExt[ext] || 0) + 1;
    try {
      const stat = await fs.stat(f);
      if (stat.size > 200 * 1024) continue; // skip very large files
      const content = await fs.readFile(f, 'utf8');
      const lines = content.split(/\r?\n/).length;
      totalLines += lines;
      languages[ext] = (languages[ext] || 0) + lines;
    } catch (e) { /* ignore unreadable files */ }
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

async function analyzeHandler(args = {}) {
  const scan = args.scan || await scanRepoHandler({ path: args.path });
  const topLang = scan.dominantLanguage || Object.keys(scan.languages)[0] || 'unknown';

  // Infer high-level purpose from manifests and repo layout
  let purpose = 'General codebase';
  if (scan.manifests.includes('package.json')) purpose = 'Node.js project (app or library)';
  else if (scan.manifests.includes('pyproject.toml')) purpose = 'Python project';
  else if (scan.manifests.includes('go.mod')) purpose = 'Go project';
  else if ((scan.topFolders || []).includes('plugins')) purpose = 'Copilot CLI plugins collection';

  // Parse README for title, intro and badges
  let readmeTitle = null;
  let readmeIntro = null;
  const badges = [];
  if (scan.readmeSummary) {
    const lines = scan.readmeSummary.split(/\r?\n/).map(l=>l.trim()).filter(Boolean);
    // title: first heading (# ...)
    for (const l of lines) {
      const m = l.match(/^#\s+(.*)/);
      if (m) { readmeTitle = m[1]; break; }
    }
    // intro: first paragraph after title or first non-heading block
    let para = [];
    let sawTitle = false;
    for (const l of lines) {
      if (!sawTitle && /^#/.test(l)) { sawTitle = true; continue; }
      if (sawTitle && l) { para.push(l); if (para.length>=2) break; }
      if (!sawTitle && l && !/^#/.test(l)) { para.push(l); if (para.length>=2) break; }
    }
    readmeIntro = para.join(' ');

    // badges: look for shields.io or badge image links
    const badgeRegex = /!\[[^\]]*\]\((https?:\/\/[^)]+shields\.io[^)]*)\)|!\[[^\]]*\]\((https?:\/\/[^)]+badge.*?\.svg)\)|\[!\[[^\]]*\]\((https?:\/\/[^)]+)\)\]\((?:https?:\/\/[^)]+)\)/ig;
    let m;
    while ((m = badgeRegex.exec(scan.readmeSummary))) {
      const url = m[1] || m[2] || m[3];
      if (url) badges.push(url);
    }
  }

  // Map repo layout to concise bullet list of capabilities/notes
  const bullets = [];
  if (scan.hasDockerfile) bullets.push('Containerized (Dockerfile)');
  if (scan.ciFiles.length) bullets.push('CI workflows present');
  if (scan.licensePresent) bullets.push('License present');
  if (!scan.ciFiles.length) bullets.push('No CI detected');
  if ((scan.topFolders||[]).includes('Scripts')) bullets.push('Includes utility scripts (Scripts/)');
  if ((scan.topFolders||[]).includes('plugins')) bullets.push('Contains plugin packages under plugins/');
  if ((scan.topFolders||[]).includes('MCP')) bullets.push('Contains MCP server configurations');

  const elevator = `${purpose} primarily in ${topLang}.`;

  // Generate prioritized actions with slightly smarter heuristics
  const actions = [];
  if (!scan.readmeSummary) actions.push({id:'add-readme', title:'Add or improve README', reason:'Missing or empty README', effort:'S'});
  else if (!readmeTitle) actions.push({id:'improve-readme-title', title:'Add clear README title', reason:'No top-level title found', effort:'S'});

  if (!scan.ciFiles.length) actions.push({id:'add-ci', title:'Add CI workflow', reason:'No CI detected', effort:'M'});
  if (!scan.licensePresent) actions.push({id:'add-license', title:'Add license', reason:'No license file', effort:'S'});

  // If this appears to be a plugin collection, suggest packaging and examples
  if ((scan.topFolders||[]).includes('plugins')) actions.push({id:'add-plugin-readmes', title:'Add plugin-level README and install docs', reason:'Plugins need per-package docs', effort:'M'});

  return { purpose, elevator, bullets, actions, readmeTitle, readmeIntro, badges };
}

async function suggestHandler(args = {}) {
  const scan = args.scan || await scanRepoHandler({ path: args.path });
  const analysis = args.analysis || await analyzeHandler({ scan });
  const checklist = [];
  if (!scan.licensePresent) checklist.push({id:'license', title:'Add LICENSE', reason:'No license file detected', effort:'S'});
  if (!scan.ciFiles.length) checklist.push({id:'ci', title:'Add CI', reason:'No CI workflows', effort:'M', example:'/.github/workflows/ci.yml'});
  if (!scan.manifests.length) checklist.push({id:'manifest', title:'Add project manifest', reason:'No package manifest found', effort:'M'});
  if (scan.fileCount < 100) checklist.push({id:'tests', title:'Add tests', reason:'Few files/test missing', effort:'M'});

  return { checklist, recommended: analysis.actions };
}

const session = await joinSession({
  tools: [
    {
      name: 'project-analyzer-scan',
      description: 'Scan a repository and return a JSON report',
      parameters: { type: 'object', properties: { path: { type: 'string' } } },
      handler: async (args) => await scanRepoHandler(args),
    },
    {
      name: 'project-analyzer-analyze',
      description: 'Analyze repository purpose from a scan report',
      parameters: { type: 'object', properties: { scan: { type: 'object' }, path: { type: 'string' } } },
      handler: async (args) => await analyzeHandler(args),
    },
    {
      name: 'project-analyzer-suggest',
      description: 'Suggest missing components based on scan and analysis',
      parameters: { type: 'object', properties: { scan: { type: 'object' }, analysis: { type: 'object' }, path: { type: 'string' } } },
      handler: async (args) => await suggestHandler(args),
    },
    {
      name: 'project-analyzer-orchestrate',
      description: 'Orchestrate background explorations and sampled scans (budgeted)',
      parameters: { type: 'object', properties: { action: { type: 'string' }, query: { type: 'string' }, maxFiles: { type: 'number' }, budget: { type: 'number' }, path: { type: 'string' } } },
      handler: async (args) => {
        const action = args.action;
        if (action === 'start-explore') {
          const maxFiles = args.maxFiles || 500;
          const files = await listFiles(args.path || '.', Math.min(maxFiles, 5000));
          const sampleSize = Math.min(200, files.length);
          const step = Math.max(1, Math.floor(files.length / sampleSize));
          const sample = files.filter((_,i)=> i % step === 0).slice(0, sampleSize);
          const summary = { sampleCount: sample.length, totalFiles: files.length, topFolders: Array.from(new Set(sample.map(f=> path.relative(path.resolve(args.path||'.'), f).split(path.sep)[0]))).slice(0,10) };
          return { agent_id: `explore-${Date.now()}`, status: 'completed', summary, sample };
        }
        return { error: 'unknown action' };
      },
    },
  ],
});
