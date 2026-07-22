'use strict';
// environments.toml — the per-machine registry of environments this harness
// operates on. Gitignored (paths differ per developer); written only by
// `add`/`remove`, never hand-edited in normal use. Deliberately a tiny TOML
// subset so the CLI stays zero-dependency:
//
//   [[environment]]
//   name = "myapp"
//   path = "/abs/path/to/myapp"
//   enabled = true

const fs = require('fs');
// Not destructured: registryPath is a getter that resolves (and can throw) only
// when a harness is actually needed. See lib/paths.js.
const paths = require('./paths');

function parse(text) {
  const envs = [];
  let cur = null;
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    if (line === '[[environment]]') { cur = { enabled: true }; envs.push(cur); continue; }
    const m = line.match(/^(\w+)\s*=\s*(.+)$/);
    if (!m || !cur) continue;
    let [, key, value] = m;
    value = value.trim();
    if (value === 'true') value = true;
    else if (value === 'false') value = false;
    else value = value.replace(/^"(.*)"$/, '$1');
    cur[key] = value;
  }
  return envs;
}

function serialize(envs) {
  const lines = ['# Environments registered with this harness (managed by `context-specs add`).', ''];
  for (const e of envs) {
    lines.push('[[environment]]');
    lines.push(`name = "${e.name}"`);
    lines.push(`path = "${e.path}"`);
    lines.push(`enabled = ${e.enabled !== false}`);
    if (e.interval) lines.push(`interval = ${e.interval}`);
    lines.push('');
  }
  return lines.join('\n');
}

function load() {
  const p = paths.registryPath;
  if (!fs.existsSync(p)) return [];
  return parse(fs.readFileSync(p, 'utf8'));
}

function save(envs) {
  fs.writeFileSync(paths.registryPath, serialize(envs));
}

function find(name) {
  return load().find((e) => e.name === name) || null;
}

// Resolve [name] the run/start/stop/logs commands take: explicit name, or the
// sole registered environment, or an error listing the choices.
function resolveOne(name) {
  const envs = load();
  if (name) {
    const env = envs.find((e) => e.name === name);
    if (!env) throw new Error(`no environment named '${name}' (registered: ${envs.map((e) => e.name).join(', ') || 'none'})`);
    return env;
  }
  const enabled = envs.filter((e) => e.enabled !== false);
  if (enabled.length === 1) return enabled[0];
  if (!enabled.length) throw new Error("no environments registered — run 'context-specs add <path>' first");
  throw new Error(`multiple environments registered — name one of: ${enabled.map((e) => e.name).join(', ')}`);
}

module.exports = { load, save, find, resolveOne, parse, serialize };
