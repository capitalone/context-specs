'use strict';
// Which environment does this command act on?
//
// One answer for `start`, `stop`, `run` and `logs`, because the rule should not
// depend on which command you happened to type:
//
//   1. you named one                      → that one
//   2. --all (where it means anything)    → every enabled environment
//   3. you are standing in an environment → that one
//   4. …or in one of its worktrees        → that one
//   5. you have exactly one registered    → that one
//   6. otherwise                          → say so, and teach the options
//
// Standing in a project repo is the common case — /intent, /env-init and PR
// review all happen there — so 3 and 4 are the point of this module. Every
// inferred choice is announced (see `notice`); silent cwd-dependent behaviour is
// how a tool becomes unpredictable.

const fs = require('fs');
const path = require('path');
const registry = require('./registry');
const { git, positionals } = require('./util');

const realpath = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
const under = (root, p) => p === root || p.startsWith(root + path.sep);

// Which registered environment is cwd inside? Safe to read the registry here —
// unlike paths.findHome(), this runs after the harness is already resolved.
function envForCwd() {
  let cwd;
  try { cwd = realpath(process.cwd()); } catch { return null; }
  const envs = registry.load();

  const direct = envs.find((e) => under(realpath(e.path), cwd));
  if (direct) return { env: direct, via: 'cwd' };

  // Feature worktrees are SIBLINGS of the environment, not descendants, so no
  // prefix match can see them. Ask git rather than parsing the worktree naming
  // convention, which the dispatcher lets projects override.
  const common = git(cwd, ['rev-parse', '--git-common-dir']);
  if (common) {
    const root = path.dirname(path.resolve(cwd, common)); // <env>/.git → <env>
    const wt = envs.find((e) => realpath(e.path) === root);
    if (wt) return { env: wt, via: 'worktree' };
  }
  return null;
}

const NOTICE = {
  cwd: (n) => `targeting '${n}' (inferred from your current directory)`,
  worktree: (n) => `targeting '${n}' (inferred from the worktree you are in)`,
  sole: (n) => `targeting '${n}' (your only environment)`,
};

function ambiguityError(command, allowAll, names) {
  const lines = [
    `'${command}' needs a target when run from the harness.`,
    `  context-specs ${command} <name>     one environment (registered: ${names.join(', ')})`,
  ];
  if (allowAll) lines.push(`  context-specs ${command} --all      every enabled environment`);
  lines.push('  (or run it from inside the environment repo — the target is then implied)');
  return new Error(lines.join('\n'));
}

// Returns { envs, source, notice }. `notice` is non-null only when the target
// was inferred, and callers print it to STDERR — it is diagnostic, and
// `context-specs logs > out.txt` must not get a targeting line prepended.
function selectTargets(args, { allowAll = true, command } = {}) {
  const name = positionals(args)[0];
  if (name) {
    const env = registry.find(name);
    if (!env) {
      const names = registry.load().map((e) => e.name);
      throw new Error(`no environment named '${name}' (registered: ${names.join(', ') || 'none'})`);
    }
    return { envs: [env], source: 'explicit', notice: null };
  }

  if (args.includes('--all')) {
    if (!allowAll) {
      throw new Error(
        `--all is not supported by '${command}' — it runs one environment at a time.\n` +
        `  name one: context-specs ${command} <name>`
      );
    }
    const envs = registry.load().filter((e) => e.enabled !== false);
    if (!envs.length) throw new Error("no environments registered — run 'context-specs add <path>' first");
    return { envs, source: 'all', notice: null };
  }

  const hit = envForCwd();
  if (hit) return { envs: [hit.env], source: hit.via, notice: NOTICE[hit.via](hit.env.name) };

  const enabled = registry.load().filter((e) => e.enabled !== false);
  if (!enabled.length) throw new Error("no environments registered — run 'context-specs add <path>' first");
  if (enabled.length === 1) {
    return { envs: [enabled[0]], source: 'sole', notice: NOTICE.sole(enabled[0].name) };
  }
  throw ambiguityError(command, allowAll, enabled.map((e) => e.name));
}

// Callers: resolve, announce, act.
function selectOne(args, opts) {
  const { envs, notice, source } = selectTargets(args, opts);
  if (notice) console.error(notice);
  return { env: envs[0], source };
}

module.exports = { selectTargets, selectOne, envForCwd };
