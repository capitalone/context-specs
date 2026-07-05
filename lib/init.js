'use strict';
// `context-specs init [name]` — create (or adopt) a HARNESS repo.
//
// The context-specs repo doubles as the template: init clones it, renames
// origin → upstream (so `git pull upstream main` is the update path and origin
// stays free for the user's own remote), and prepares the per-machine pieces
// (registry, state/). Run with no args inside an existing clone, it "adopts"
// that clone as a harness instead.

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { HOME, registryPath, registryExamplePath } = require('./paths');
const { tryRun, git, confirm } = require('./util');

const TEMPLATE_URL = process.env.CONTEXT_SPECS_TEMPLATE || 'https://github.com/capitalone/context-specs.git';

async function adopt(root) {
  // Point `upstream` at the template so `context-specs`/git updates have a home.
  const remotes = (git(root, ['remote']) || '').split('\n').filter(Boolean);
  if (!remotes.includes('upstream')) {
    const originUrl = git(root, ['remote', 'get-url', 'origin']);
    if (originUrl && originUrl.replace(/\.git$/, '') === TEMPLATE_URL.replace(/\.git$/, '')) {
      git(root, ['remote', 'rename', 'origin', 'upstream']);
      console.log('renamed origin → upstream (the template; your own remote can take origin)');
    } else {
      git(root, ['remote', 'add', 'upstream', TEMPLATE_URL]);
      console.log(`added upstream → ${TEMPLATE_URL}`);
    }
  }
  if (!fs.existsSync(path.join(root, 'environments.toml'))) {
    const example = path.join(root, 'environments.example.toml');
    fs.writeFileSync(path.join(root, 'environments.toml'),
      fs.existsSync(example) ? fs.readFileSync(example, 'utf8') : '# managed by `context-specs add`\n');
  }
  fs.mkdirSync(path.join(root, 'state'), { recursive: true });
  console.log(`harness ready at ${root}`);

  if (git(root, ['remote', 'get-url', 'origin']) === null && tryRun('sh', ['-c', 'command -v gh']) !== null) {
    if (await confirm('Create a private GitHub repo for this harness (gh repo create)?')) {
      try {
        execFileSync('gh', ['repo', 'create', path.basename(root), '--private', '--source', root, '--push'], { stdio: 'inherit' });
      } catch {
        console.log('gh repo create failed — you can create and push a remote later.');
      }
    }
  }
  console.log("\nNext: register your first environment — 'context-specs add <path-to-project>'");
}

module.exports = async function init(args) {
  const name = args[0];
  // Adopt mode: we ARE running from inside a harness clone (the CLI's own HOME).
  if (!name) {
    await adopt(HOME);
    return;
  }
  const dest = path.resolve(name);
  if (fs.existsSync(dest)) throw new Error(`${dest} already exists`);
  console.log(`cloning ${TEMPLATE_URL} → ${dest}`);
  execFileSync('git', ['clone', '--quiet', TEMPLATE_URL, dest], { stdio: 'inherit' });
  git(dest, ['remote', 'rename', 'origin', 'upstream']);
  // Hand off to the CLONE's own CLI so paths resolve inside it.
  execFileSync(process.execPath, [path.join(dest, 'bin', 'context-specs'), 'init'], { stdio: 'inherit' });
  console.log(`\ncd ${name}`);
};
