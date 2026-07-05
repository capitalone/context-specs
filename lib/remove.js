'use strict';
// Unregister an environment. Deliberately conservative: only the registry entry
// is removed. The environment's files (symlinks, .gitignore block, committed
// artifacts) and its state dir are left in place and printed for manual cleanup
// — deleting things in a repo we no longer manage is not this command's call.

const fs = require('fs');
const registry = require('./registry');
const { stateDir, pidFile } = require('./paths');
const { isPidAlive } = require('./util');

module.exports = async function remove(args) {
  const name = args[0];
  if (!name) throw new Error('usage: context-specs remove <name>');
  const envs = registry.load();
  const env = envs.find((e) => e.name === name);
  if (!env) throw new Error(`no environment named '${name}'`);

  const pf = pidFile(name);
  if (fs.existsSync(pf) && isPidAlive(parseInt(fs.readFileSync(pf, 'utf8'), 10))) {
    throw new Error(`supervisor for '${name}' is running — 'context-specs stop ${name}' first`);
  }

  registry.save(envs.filter((e) => e.name !== name));
  console.log(`Unregistered '${name}'. Left in place (delete manually if you want them gone):`);
  console.log(`  ${env.path}/.claude/  symlinks + the managed .gitignore block`);
  console.log(`  ${stateDir(name)}  runtime state and logs`);
};
