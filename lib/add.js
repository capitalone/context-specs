'use strict';
// `context-specs add <path>` — the deterministic half of environment setup.
// Registers the repo, symlinks the canonical skills/agents into it, and writes
// the managed .gitignore block. The probabilistic half — AGENTS.md,
// bootstrap-worktree.sh, local-checks, the Expert skeleton, a project-owned
// /intent — is /env-init's job, run by the developer in a Claude session
// inside the environment afterward.

const fs = require('fs');
const path = require('path');
const registry = require('./registry');
const { linkEnv, ensureGitignore } = require('./link');
const { logsDir } = require('./paths');
const { git, positionals, flagValue } = require('./util');

module.exports = async function add(args) {
  const nameFlag = flagValue(args, '--name');
  const target = positionals(args)[0];
  if (!target) throw new Error('usage: context-specs add <path> [--name <n>]');

  const envPath = path.resolve(target);
  if (!fs.existsSync(envPath)) throw new Error(`no such directory: ${envPath}`);
  if (git(envPath, ['rev-parse', '--git-dir']) === null) {
    throw new Error(`${envPath} is not a git repository`);
  }
  if (git(envPath, ['remote', 'get-url', 'origin']) === null) {
    console.warn('warn: no `origin` remote — the harness claims PRDs and opens PRs through origin; add one before starting the loops.');
  }

  const name = nameFlag || path.basename(envPath);
  const envs = registry.load();
  const existing = envs.find((e) => e.name === name);
  if (existing && existing.path !== envPath) {
    throw new Error(`name '${name}' is already registered for ${existing.path} — pass --name to disambiguate`);
  }

  const { linked, agents, ejected } = linkEnv(envPath);
  ensureGitignore(envPath);
  if (!existing) {
    envs.push({ name, path: envPath, enabled: true });
    registry.save(envs);
  }
  fs.mkdirSync(logsDir(name), { recursive: true });

  console.log(`Registered environment '${name}' → ${envPath}`);
  console.log(`  linked ${linked.length} skills + ${agents.length} agents (gitignored symlinks)`);
  if (ejected.length) console.log(`  ejected (project-owned): ${ejected.join(', ')}`);
  console.log('');
  console.log('Next: the Software 3.0 half. In the environment, run the setup skill:');
  console.log(`  cd ${envPath}`);
  console.log('  claude');
  console.log('  /env-init');
  console.log('');
  console.log("Once its PR is merged: 'context-specs start' (or 'run' for one foreground pass).");
};
