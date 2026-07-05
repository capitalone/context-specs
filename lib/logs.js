'use strict';
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const registry = require('./registry');
const { logsDir } = require('./paths');

module.exports = async function logs(args) {
  const follow = args.includes('-f') || args.includes('--follow');
  const which = args.includes('--learn') ? 'learn.log'
    : args.includes('--supervisor') ? 'supervisor.log' : 'build.log';
  const env = registry.resolveOne(args.find((a) => !a.startsWith('-')));
  const file = path.join(logsDir(env.name), which);
  if (!fs.existsSync(file)) { console.log(`no ${which} yet for '${env.name}' (${file})`); return; }
  if (follow) {
    spawn('tail', ['-n', '50', '-f', file], { stdio: 'inherit' });
    return new Promise(() => {}); // tail owns the terminal until Ctrl-C
  }
  process.stdout.write(fs.readFileSync(file, 'utf8'));
};
