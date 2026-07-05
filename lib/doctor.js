'use strict';
// Health checks for the harness repo, the registry, and every registered
// environment. Absorbs the old harness-init preflight.sh, plus the failure
// modes the two-tier split introduces (broken symlinks after a move, leftover
// single-repo-era artifacts). Report-only: prints [ok]/[warn]/[MISS], never
// mutates. Exits 1 if any [MISS].

const fs = require('fs');
const path = require('path');
const registry = require('./registry');
const { HOME, scriptsDir, stateRoot, registryPath } = require('./paths');
const { tryRun, git } = require('./util');
const { canonicalSkills, canonicalAgents, GITIGNORE_START } = require('./link');

let missed = false;
const ok = (m) => console.log(`  [ok]   ${m}`);
const warn = (m) => console.log(`  [warn] ${m}`);
const miss = (m) => { console.log(`  [MISS] ${m}`); missed = true; };

function checkHarness() {
  console.log(`Harness repo: ${HOME}`);
  const major = parseInt(process.versions.node.split('.')[0], 10);
  major >= 18 ? ok(`node ${process.versions.node}`) : miss(`node >=18 required (found ${process.versions.node})`);

  for (const [cmd, why, fatal] of [
    ['bash', 'runs the dispatcher', true],
    ['git', 'everything', true],
    ['gh', 'PR creation, review polling, STUCK signals', true],
    ['claude', "the dispatcher shells out to 'claude -p'", true],
    ['flock', 'tick serialization (second line of defense behind the supervisor)', false],
    ['uuidgen', 'session ids (falls back to /proc or a pseudo-id)', false],
  ]) {
    if (tryRun('sh', ['-c', `command -v ${cmd}`]) !== null) ok(`${cmd} on PATH`);
    else (fatal ? miss : warn)(`${cmd} not on PATH — ${why}`);
  }
  if (tryRun('gh', ['auth', 'status']) !== null) ok('gh authenticated');
  else warn('gh not authenticated (gh auth login) — PR operations will fail');

  for (const s of ['poll-and-dispatch.sh', 'learn-dispatch.sh']) {
    const f = path.join(scriptsDir, s);
    if (!fs.existsSync(f)) miss(`${s} missing from scripts/`);
    else if (!(fs.statSync(f).mode & 0o100)) miss(`${s} not executable (chmod +x)`);
    else ok(`scripts/${s} executable`);
  }
  fs.existsSync(path.join(scriptsDir, 'harness-lib.sh')) ? ok('scripts/harness-lib.sh present') : miss('scripts/harness-lib.sh missing');

  try { fs.mkdirSync(stateRoot, { recursive: true }); fs.accessSync(stateRoot, fs.constants.W_OK); ok('state/ writable'); }
  catch { miss('state/ not writable'); }

  if (!fs.existsSync(registryPath)) warn("no environments.toml yet — run 'context-specs add <path>'");
  else { try { registry.load(); ok('environments.toml parses'); } catch (e) { miss(`environments.toml unreadable: ${e.message}`); } }
}

function checkEnv(env) {
  console.log(`\nEnvironment '${env.name}': ${env.path}`);
  if (!fs.existsSync(env.path)) { miss('path does not exist'); return; }
  if (git(env.path, ['rev-parse', '--git-dir']) === null) { miss('not a git repository'); return; }
  git(env.path, ['remote', 'get-url', 'origin']) !== null ? ok('origin remote') : miss('no origin remote — the harness works entirely through origin');

  // Tier-2 artifacts (created by /env-init).
  fs.existsSync(path.join(env.path, '.harness', 'env')) ? ok('.harness/env config') : warn('.harness/env missing — run /env-init in this environment');
  fs.existsSync(path.join(env.path, 'AGENTS.md')) ? ok('AGENTS.md') : warn('AGENTS.md missing — run /env-init');
  const bootstrap = path.join(env.path, 'scripts', 'bootstrap-worktree.sh');
  if (!fs.existsSync(bootstrap)) warn('scripts/bootstrap-worktree.sh missing — fresh worktrees will not be provisioned or re-linked');
  else if (!fs.readFileSync(bootstrap, 'utf8').includes('context-specs')) warn('bootstrap-worktree.sh lacks the `context-specs link` header — fresh worktrees will miss the tier-1 skills');
  else ok('bootstrap-worktree.sh with link header');
  fs.existsSync(path.join(env.path, '.claude', 'skills', 'intent', 'SKILL.md')) ? ok('project-owned /intent') : warn('/intent not installed — run /env-init');
  fs.existsSync(path.join(env.path, '.claude', 'skills', 'expert', 'SKILL.md')) ? ok('Expert (long-term memory)') : warn('Expert skeleton not seeded — run /env-init');

  // Symlink integrity for every canonical skill/agent.
  let ejected = [];
  for (const { name, dir } of canonicalSkills()) {
    const lp = path.join(env.path, '.claude', 'skills', name);
    let st = null;
    try { st = fs.lstatSync(lp); } catch {}
    if (!st) miss(`skill '${name}' not linked — run 'context-specs link ${env.path}'`);
    else if (!st.isSymbolicLink()) ejected.push(name);
    else if (fs.realpathSync(lp) !== fs.realpathSync(dir)) warn(`skill '${name}' links outside this harness (${fs.readlinkSync(lp)})`);
  }
  for (const { name, file } of canonicalAgents()) {
    const lp = path.join(env.path, '.claude', 'agents', name);
    let st = null;
    try { st = fs.lstatSync(lp); } catch {}
    if (!st) miss(`agent '${name}' not linked — run 'context-specs link ${env.path}'`);
    else if (st.isSymbolicLink() && fs.realpathSync(lp) !== fs.realpathSync(file)) warn(`agent '${name}' links outside this harness`);
  }
  if (ejected.length) ok(`ejected (project-owned forks): ${ejected.join(', ')}`);
  const gi = path.join(env.path, '.gitignore');
  fs.existsSync(gi) && fs.readFileSync(gi, 'utf8').includes(GITIGNORE_START)
    ? ok('managed .gitignore block')
    : warn("managed .gitignore block missing — re-run 'context-specs add'");

  // Leftovers from the single-repo era (pre-two-tier installs).
  const legacy = ['scripts/poll-and-dispatch.sh', 'scripts/harness-tick.sh', 'scripts/harness-lib.sh', 'scripts/learn-tick.sh',
    '.claude/skills/poll-and-dispatch', '.claude/skills/learn-loop']
    .filter((f) => fs.existsSync(path.join(env.path, f)));
  if (legacy.length) {
    warn(`legacy single-repo harness artifacts found (two dispatchers would confuse, though claims stay atomic): ${legacy.join(', ')}`);
    warn('  remove them in the environment: git rm ' + legacy.join(' '));
  }
}

module.exports = async function doctor() {
  checkHarness();
  for (const env of registry.load()) checkEnv(env);
  console.log('');
  if (missed) { console.log('doctor: problems found (see [MISS] above)'); process.exit(1); }
  console.log('doctor: healthy');
};
