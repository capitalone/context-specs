'use strict';
// One-shot, deterministic render of the whole harness's state. Everything is
// derived from artifacts — committed sentinels on the feature branches, counter
// and sentinel files in state/<env>/, the pidfile — exactly the "state lives on
// disk + branches" invariant, read instead of written. No gh calls: fast and
// offline; PR-level state is one click away on GitHub. Remote-tracking refs are
// as of the last fetch (a tick fetches every interval); pass --fetch to update
// them first.

const fs = require('fs');
const path = require('path');
const registry = require('./registry');
const { stateDir, pidFile } = require('./paths');
const { git, renderTable, isPidAlive } = require('./util');

// Phase from committed sentinels, mirroring the dispatcher's if/elif chain.
function phaseFor(envPath, feature) {
  const has = (f) => git(envPath, ['cat-file', '-e', `origin/feature/${feature}:specs/${feature}/${f}`]) !== null;
  if (!has('.planning-done')) return 'spec-planning';
  if (!has('.validated')) return 'spec-validate';
  if (!has('.prd-passed')) return 'implement';
  return 'checks/PR';
}

function counterFor(name, feature, phase) {
  const files = {
    'spec-planning': `planning-attempts-${feature}`,
    'spec-validate': `validate-attempts-${feature}`,
    implement: `implement-attempts-${feature}`,
    'checks/PR': `feedback-rounds-${feature}`,
  };
  const alt = phase === 'checks/PR' ? `local-check-attempts-${feature}` : null;
  let n = 0;
  for (const f of [files[phase], alt].filter(Boolean)) {
    try { n = Math.max(n, parseInt(fs.readFileSync(path.join(stateDir(name), f), 'utf8'), 10) || 0); } catch {}
  }
  return n || '';
}

module.exports = async function status(args) {
  const envs = registry.load();
  if (!envs.length) { console.log("no environments registered — 'context-specs add <path>'"); return; }

  const rows = [['env', 'feature', 'phase', 'attempts', 'flag', 'supervisor']];
  for (const env of envs) {
    if (args.includes('--fetch')) git(env.path, ['fetch', '--quiet', 'origin']);
    let sup = 'stopped';
    try {
      const pid = parseInt(fs.readFileSync(pidFile(env.name), 'utf8'), 10);
      if (isPidAlive(pid)) sup = `running (${pid})`;
    } catch {}
    if (env.enabled === false) sup = 'disabled';

    const refs = git(env.path, ['for-each-ref', '--format=%(refname:lstrip=4)', 'refs/remotes/origin/feature/']) || '';
    const features = refs.split('\n').filter(Boolean)
      .filter((f) => git(env.path, ['cat-file', '-e', `origin/feature/${f}:prds/${f}/prd.md`]) !== null);

    if (!features.length) {
      rows.push([env.name, '—', 'idle', '', '', sup]);
      continue;
    }
    for (const f of features) {
      const sd = stateDir(env.name);
      const flag = fs.existsSync(path.join(sd, `stuck-${f}`)) ? 'STUCK'
        : fs.existsSync(path.join(sd, `human-review-${f}`)) ? 'HUMAN_REVIEW' : '';
      const phase = phaseFor(env.path, f);
      rows.push([env.name, f, phase, counterFor(env.name, f, phase), flag, sup]);
    }
  }
  console.log(renderTable(rows));
  if (!args.includes('--fetch')) console.log('\n(branch state as of each environment’s last fetch — pass --fetch to refresh)');
};
