'use strict';
const path = require('path');

// The harness repo root. The CLI always lives at <harness>/bin + <harness>/lib,
// so its own location IS the harness location — no lookup, no env var needed.
const HOME = path.resolve(__dirname, '..');

module.exports = {
  HOME,
  scriptsDir: path.join(HOME, 'scripts'),
  skillsDir: path.join(HOME, 'skills'),
  subagentsDir: path.join(HOME, 'subagents'),
  registryPath: path.join(HOME, 'environments.toml'),
  registryExamplePath: path.join(HOME, 'environments.example.toml'),
  stateRoot: path.join(HOME, 'state'),
  stateDir: (name) => path.join(HOME, 'state', name),
  logsDir: (name) => path.join(HOME, 'state', name, 'logs'),
  pidFile: (name) => path.join(HOME, 'state', name, 'supervisor.pid'),
  binPath: path.join(HOME, 'bin', 'context-specs'),
};
