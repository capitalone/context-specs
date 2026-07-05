'use strict';
const { execFileSync } = require('child_process');
const readline = require('readline');

// Run a command, return trimmed stdout, or null on any failure. The callers
// that need the distinction between "empty output" and "failed" test for null.
function tryRun(cmd, args, opts = {}) {
  try {
    return execFileSync(cmd, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], ...opts }).trim();
  } catch {
    return null;
  }
}

// git against a specific repo without changing cwd.
function git(repo, args) {
  return tryRun('git', ['-C', repo, ...args]);
}

function ask(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => rl.question(question, (a) => { rl.close(); resolve(a.trim()); }));
}

async function confirm(question) {
  const a = await ask(`${question} [y/N] `);
  return /^y(es)?$/i.test(a);
}

// Render rows as a padded text table. rows = array of arrays; first row = header.
function renderTable(rows) {
  if (!rows.length) return '';
  const widths = rows[0].map((_, i) => Math.max(...rows.map((r) => String(r[i] ?? '').length)));
  const line = (r) => r.map((c, i) => String(c ?? '').padEnd(widths[i])).join('  ').trimEnd();
  return [line(rows[0]), widths.map((w) => '-'.repeat(w)).join('  '), ...rows.slice(1).map(line)].join('\n');
}

function isPidAlive(pid) {
  try { process.kill(pid, 0); return true; } catch { return false; }
}

module.exports = { tryRun, git, ask, confirm, renderTable, isPidAlive };
