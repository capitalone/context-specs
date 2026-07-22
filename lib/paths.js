'use strict';
// Two roots, and they are not the same thing.
//
//   PKG  — the npm package. The CANONICAL content source: skills/, subagents/
//          and scripts/ exactly as shipped. Always resolvable, since it is this
//          file's own package.
//   HOME — the harness: the user's OWN git repo, holding a vendored copy of that
//          content plus environments.toml and state/. The CLI is installed
//          globally, so its location says nothing about where the harness is.
//
// HOME resolution order:
//   1. CONTEXT_SPECS_HOME — set by anything that already knows. The supervisor
//      exports it when it spawns the dispatchers; the dispatchers export it when
//      they invoke the CLI back. Whoever knows, tells; whoever is told, believes.
//   2. Walk up from cwd for the marker.
//   3. Hard error. Never fall back to PKG: a silent fallback is how you get a
//      half-working harness writing state into a node_modules directory.
//
// Scalar paths are GETTERS — they throw when there is no harness. Do NOT
// destructure them at module load (`const { scriptsDir } = require('./paths')`)
// or the throw happens at require time, which breaks `init` and `--help`.
// Destructuring the function-valued exports is fine; they resolve when called.

const fs = require('fs');
const path = require('path');

const PKG = path.resolve(__dirname, '..');

// The directories `init` vendors into a harness and `update` 3-way merges.
const VENDORED = ['skills', 'subagents', 'scripts'];

const MARKER = path.join('.context-specs', 'manifest.json');

const isHarness = (dir) => fs.existsSync(path.join(dir, MARKER));

// A registered environment points back at its harness through the symlinks
// `context-specs add` created, which are absolute:
//
//   <env>/.claude/skills/<name>    → <HOME>/skills/<group>/<name>
//   <env>/.claude/agents/<file>.md → <HOME>/subagents/<file>.md
//
// So standing in a project repo is enough to find the harness that drives it.
// (Same idiom documented in env-init/SKILL.md — readlink a skill, strip the tail.)
//
// This must never read the registry: registry.load() goes through
// paths.registryPath → requireHome(), and requireHome() memoizes only on
// success, so a registry read from in here recurses until the stack blows.
// Everything below is raw fs/path over a candidate root passed as a string.
const BACKREFS = [
  { container: ['.claude', 'skills'], up: 3, segment: 'skills' },
  { container: ['.claude', 'agents'], up: 2, segment: 'subagents' },
];

function harnessFromBackrefs(dir) {
  for (const { container, up, segment } of BACKREFS) {
    const c = path.join(dir, ...container);
    // Cheap miss for every directory that is not an environment repo.
    try { if (!fs.statSync(c).isDirectory()) continue; } catch { continue; }

    for (const entry of fs.readdirSync(c).sort()) {
      const p = path.join(c, entry);
      let st;
      try { st = fs.lstatSync(p); } catch { continue; }
      // Not a symlink means a project-owned fork: /intent (excluded from
      // linking), the Expert, or an ejected skill. Skipping is normal.
      if (!st.isSymbolicLink()) continue;

      let target;
      // path.resolve is string arithmetic and never touches disk, so a link
      // whose target upstream has since renamed still yields the right root.
      try { target = path.resolve(c, fs.readlinkSync(p)); } catch { continue; }

      let root = target;
      for (let i = 0; i < up; i++) root = path.dirname(root);
      // The first segment below the candidate root must be the directory we
      // vendor into — this is what distinguishes our links from some other
      // tool's that happens to live in .claude/.
      if (path.relative(root, target).split(path.sep)[0] !== segment) continue;

      if (isHarness(root)) return root;
    }
  }
  return null;
}

function findHome() {
  // Whoever knows, tells. The dispatchers export this, and it is the hot path
  // (`context-specs link` runs on every tick), so it stays first and does no I/O.
  if (process.env.CONTEXT_SPECS_HOME) return path.resolve(process.env.CONTEXT_SPECS_HOME);

  // One walk, both markers per level: the nearest enclosing context-specs root
  // wins, and a real harness outranks a pointer to one. That stays sensible if
  // someone nests a project inside the harness tree.
  let dir = process.cwd();
  for (;;) {
    if (isHarness(dir)) return dir;
    const viaEnv = harnessFromBackrefs(dir);
    if (viaEnv) return viaEnv;
    const up = path.dirname(dir);
    if (up === dir) return null;
    dir = up;
  }
}

let memo;
let resolving = false;
function requireHome() {
  if (memo !== undefined) return memo;
  // The recursion above is invisible at the call site; without this guard a
  // future edit that reads a path getter from findHome() blows the stack with
  // no clue why.
  if (resolving) {
    throw new Error('internal: harness resolution re-entered — something inside findHome() read a path getter');
  }
  let home;
  resolving = true;
  try { home = findHome(); } finally { resolving = false; }
  if (!home) {
    throw new Error(
      'not inside a context-specs harness (no .context-specs/manifest.json found),\n' +
      '  and this directory is not a registered environment.\n' +
      "  cd into your harness, run 'context-specs add <path>' for this repo first,\n" +
      '  or set CONTEXT_SPECS_HOME.\n' +
      '  Create a harness with: context-specs init <name>'
    );
  }
  memo = home;
  return memo;
}

module.exports = {
  // --- the package: canonical content source ------------------------------
  PKG,
  VENDORED,
  pkgBinPath: path.join(PKG, 'bin', 'context-specs'),
  registryExamplePath: path.join(PKG, 'environments.example.toml'),

  // --- the harness --------------------------------------------------------
  findHome,
  requireHome,
  get HOME() { return requireHome(); },
  get scriptsDir() { return path.join(requireHome(), 'scripts'); },
  get skillsDir() { return path.join(requireHome(), 'skills'); },
  get subagentsDir() { return path.join(requireHome(), 'subagents'); },
  get registryPath() { return path.join(requireHome(), 'environments.toml'); },
  get stateRoot() { return path.join(requireHome(), 'state'); },
  get csDir() { return path.join(requireHome(), '.context-specs'); },
  get manifestPath() { return path.join(requireHome(), '.context-specs', 'manifest.json'); },
  get baseDir() { return path.join(requireHome(), '.context-specs', 'base'); },
  get reportPath() { return path.join(requireHome(), '.context-specs', 'update-report.md'); },

  stateDir: (name) => path.join(requireHome(), 'state', name),
  logsDir: (name) => path.join(requireHome(), 'state', name, 'logs'),
  pidFile: (name) => path.join(requireHome(), 'state', name, 'supervisor.pid'),
};
