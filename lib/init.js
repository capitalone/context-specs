'use strict';
// `context-specs init [name]` — create a HARNESS repo.
//
// The harness is the user's OWN git repo, not a fork of ours: init scaffolds it
// and vendors the canonical skills, subagents and dispatchers into it. There is
// no `upstream` remote and no clone — upgrades come from `npm i -g
// context-specs@latest` followed by `context-specs update`, which 3-way merges
// the new version against whatever the user has since edited.
//
// Run with no argument, init scaffolds in the current directory.

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const paths = require('./paths');
const vendor = require('./vendor');
const { tryRun, git, confirm } = require('./util');

const GITIGNORE = `# Per-machine harness runtime (managed by the context-specs CLI)
/state/
/environments.toml
/.context-specs/update-report*.md
node_modules/
`;

module.exports = async function init(args) {
  const name = args.find((a) => !a.startsWith('--'));
  const dest = name ? path.resolve(name) : process.cwd();

  if (fs.existsSync(path.join(dest, '.context-specs', 'manifest.json'))) {
    throw new Error(`${dest} is already a harness — run 'context-specs update' to pull a newer version`);
  }
  fs.mkdirSync(dest, { recursive: true });

  if (git(dest, ['rev-parse', '--git-dir']) === null) {
    execFileSync('git', ['init', '--quiet', dest], { stdio: 'inherit' });
    console.log(`initialized a git repo at ${dest}`);
  }

  const files = vendor.vendorAll(paths.PKG, dest);
  console.log(`vendored ${files.length} files (skills, subagents, dispatchers) from context-specs v${vendor.pkgVersion()}`);

  const registryFile = path.join(dest, 'environments.toml');
  if (!fs.existsSync(registryFile)) {
    const example = paths.registryExamplePath;
    fs.writeFileSync(registryFile, fs.existsSync(example)
      ? fs.readFileSync(example, 'utf8')
      : '# managed by `context-specs add`\n');
  }
  fs.mkdirSync(path.join(dest, 'state'), { recursive: true });

  const gitignore = path.join(dest, '.gitignore');
  if (!fs.existsSync(gitignore)) fs.writeFileSync(gitignore, GITIGNORE);

  // Commit: the harness's own git history is the undo for every later `update`,
  // so BASE has to be committed before anything can diverge from it.
  git(dest, ['add', '-A']);
  git(dest, ['commit', '-m', `context-specs init (vendored v${vendor.pkgVersion()})`]);

  console.log(`\nharness ready at ${dest}`);

  // Only offer this interactively: with no TTY, readline never resolves and the
  // process exits before printing the next steps.
  if (process.stdin.isTTY && git(dest, ['remote', 'get-url', 'origin']) === null && tryRun('sh', ['-c', 'command -v gh']) !== null) {
    if (await confirm('Create a private GitHub repo for this harness (gh repo create)?')) {
      try {
        execFileSync('gh', ['repo', 'create', path.basename(dest), '--private', '--source', dest, '--push'], { stdio: 'inherit' });
      } catch {
        console.log('gh repo create failed — you can create and push a remote later.');
      }
    }
  }

  console.log('');
  console.log('Next: register your first environment:');
  if (name) console.log(`  cd ${name}`);
  console.log('  context-specs add <path-to-project>');
};
