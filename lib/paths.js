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

function findHome() {
  if (process.env.CONTEXT_SPECS_HOME) return path.resolve(process.env.CONTEXT_SPECS_HOME);
  let dir = process.cwd();
  for (;;) {
    if (fs.existsSync(path.join(dir, MARKER))) return dir;
    const up = path.dirname(dir);
    if (up === dir) return null;
    dir = up;
  }
}

let memo;
function requireHome() {
  if (memo !== undefined) return memo;
  const home = findHome();
  if (!home) {
    throw new Error(
      'not inside a context-specs harness (no .context-specs/manifest.json found).\n' +
      '  cd into your harness, or set CONTEXT_SPECS_HOME.\n' +
      '  Create one with: context-specs init <name>'
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
