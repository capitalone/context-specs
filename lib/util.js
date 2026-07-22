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

// Flags this CLI's commands take a VALUE for. Their value is not a positional.
const VALUED_FLAGS = new Set(['--name']);

// The one positional predicate, used by every command. Excludes single-dash
// flags too (so a future `-a` is not mistaken for an environment name), and
// skips the value of a valued flag — without that, `add --name foo /path`
// reads `foo` as the path.
function positionals(args) {
  return args.filter((a, i) =>
    !a.startsWith('-') && !(i > 0 && VALUED_FLAGS.has(args[i - 1])));
}

// Read `--flag value` or `--flag=value`.
function flagValue(args, flag) {
  const i = args.indexOf(flag);
  if (i !== -1) return args[i + 1] ?? null;
  const eq = args.find((a) => a.startsWith(`${flag}=`));
  return eq ? eq.slice(flag.length + 1) : null;
}

module.exports = { tryRun, git, ask, confirm, renderTable, isPidAlive, positionals, flagValue };
