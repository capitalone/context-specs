'use strict';
// `context-specs update` — re-vendor from the installed package, 3-way merging
// whatever the developer has edited since.
//
// Users are MEANT to evolve their harness skills, so a blind overwrite is wrong
// and a blind skip is equally wrong. With BASE on disk (.context-specs/base/) we
// have a real common ancestor, so most files resolve mechanically:
//
//   upstream didn't touch it  → nothing to do        (most files, most releases)
//   user never touched it     → overwrite
//   only one side changed     → take that side
//   both changed, disjoint    → git merge-file resolves it
//   both changed, same lines  → conflict markers, a human decides
//
// The one case git cannot judge is prose. Skills are Markdown instructing an
// agent: two hunks that merge cleanly line-by-line can still contradict each
// other, and git will never say so. Those go to /update-harness as
// `merged-needs-review` — the Software 3.0 half of this command.
//
// This never auto-applies anything the human can't undo: it refuses on a dirty
// tree precisely so the harness's own `git diff` / `git checkout` IS the undo.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const paths = require('./paths');
const vendor = require('./vendor');
const registry = require('./registry');
const { git, isPidAlive } = require('./util');
const { linkEnv, ensureGitignore } = require('./link');

// Tiers that need a human. Everything else applied without question.
const ATTENTION = new Set(['conflict', 'conflict-binary', 'merged-needs-review', 'local-deleted', 'removed-kept', 'added-collision']);

// git merge-file, capturing output even on the non-zero exit that signals
// conflicts. util.tryRun collapses failure to null, so it cannot be reused.
function mergeFile(local, base, upstream) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cs-merge-'));
  try {
    const f = (n, buf) => { const p = path.join(dir, n); fs.writeFileSync(p, buf); return p; };
    const args = ['merge-file', '-p', '-L', 'local', '-L', 'base', '-L', 'upstream',
      f('local', local), f('base', base), f('upstream', upstream)];
    try {
      return { merged: execFileSync('git', args, { maxBuffer: 64 * 1024 * 1024 }), conflicts: 0 };
    } catch (err) {
      if (err.stdout === undefined || err.status === undefined || err.status < 0) throw err;
      return { merged: err.stdout, conflicts: err.status };
    }
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function classify(home, pkgRoot, baseRoot, manifestFiles, upstreamFiles) {
  const upstream = new Set(upstreamFiles);
  const known = new Set(manifestFiles);
  const plan = [];

  for (const rel of [...new Set([...manifestFiles, ...upstreamFiles])].sort()) {
    const B = vendor.read(baseRoot, rel);
    const L = vendor.read(home, rel);
    const U = upstream.has(rel) ? vendor.read(pkgRoot, rel) : null;

    // Upstream dropped the file.
    if (!upstream.has(rel)) {
      if (L === null) plan.push({ rel, tier: 'removed' });
      else if (B !== null && L.equals(B)) plan.push({ rel, tier: 'removed' });
      else plan.push({ rel, tier: 'removed-kept' });
      continue;
    }

    // Upstream added a file we've never vendored.
    if (!known.has(rel)) {
      if (L === null) plan.push({ rel, tier: 'added', bytes: U });
      else if (L.equals(U)) plan.push({ rel, tier: 'unchanged' });
      else plan.push({ rel, tier: 'added-collision' });
      continue;
    }

    if (B !== null && B.equals(U)) { plan.push({ rel, tier: 'unchanged' }); continue; }
    if (L === null) { plan.push({ rel, tier: 'local-deleted' }); continue; }
    if (B !== null && L.equals(B)) { plan.push({ rel, tier: 'updated', bytes: U }); continue; }
    if (L.equals(U)) { plan.push({ rel, tier: 'unchanged' }); continue; }

    // Both sides moved.
    if (!vendor.isText(L) || !vendor.isText(U)) { plan.push({ rel, tier: 'conflict-binary' }); continue; }
    const { merged, conflicts } = mergeFile(L, B || Buffer.alloc(0), U);
    if (conflicts > 0) plan.push({ rel, tier: 'conflict', bytes: merged, conflicts });
    else if (rel.endsWith('.md')) plan.push({ rel, tier: 'merged-needs-review', bytes: merged });
    else plan.push({ rel, tier: 'merged', bytes: merged });
  }
  return plan;
}

// Why does the local edit exist? The harness is a git repo, so its own history
// answers that — and it is what lets /update-harness open with a reason instead
// of asking the human to remember.
function provenance(home, rel) {
  return git(home, ['log', '-1', '--format=%h — %s (%ad)', '--date=short', '--', rel]) || null;
}

function report(home, from, to, plan, links) {
  const count = (t) => plan.filter((p) => p.tier === t).length;
  const L = [];
  L.push(`# Harness update report — v${from} → v${to}`);
  L.push('');
  L.push(`Generated ${new Date().toISOString()} · harness \`${home}\` · HEAD ${git(home, ['rev-parse', '--short', 'HEAD']) || '(none)'}`);
  L.push('');
  L.push('## Summary');
  L.push('');
  L.push('| tier | count |');
  L.push('| ---- | ----- |');
  for (const [tier, label] of [
    ['updated', 'updated (you had not edited these)'],
    ['added', 'added'],
    ['merged', 'merged cleanly'],
    ['merged-needs-review', 'merged — needs semantic review'],
    ['conflict', 'conflict — markers in file'],
    ['conflict-binary', 'conflict — binary, not merged'],
    ['local-deleted', 'kept deleted (you removed it; upstream still ships it)'],
    ['removed', 'removed (upstream dropped it)'],
    ['removed-kept', 'removed upstream — kept (you had edited it)'],
    ['added-collision', 'added upstream — you already had a different file there'],
  ]) if (count(tier)) L.push(`| ${label} | ${count(tier)} |`);
  L.push('');

  const attention = plan.filter((p) => ATTENTION.has(p.tier));
  if (attention.length) {
    L.push('## Needs your attention');
    L.push('');
    attention.forEach((p, i) => {
      L.push(`### ${i + 1}. ${p.tier.toUpperCase()} — \`${p.rel}\``);
      L.push('');
      if (p.tier === 'conflict') {
        L.push(`Both you and upstream changed the same lines (${p.conflicts} hunk${p.conflicts === 1 ? '' : 's'}).`);
        L.push('The file on disk carries `<<<<<<< local` markers and is NOT usable until resolved.');
      } else if (p.tier === 'merged-needs-review') {
        L.push('git merged this cleanly, but both sides edited prose. A line-based merge cannot');
        L.push('tell whether the result still says one coherent thing — read the whole file.');
      } else if (p.tier === 'local-deleted') {
        L.push('You deleted this file. Upstream still ships it and has changed it. Left deleted.');
      } else if (p.tier === 'removed-kept') {
        L.push('Upstream removed this file, but you had edited it. Kept, so your work is not lost.');
      } else if (p.tier === 'added-collision') {
        L.push('Upstream added this file and you already had a different one at that path. Yours kept.');
      } else if (p.tier === 'conflict-binary') {
        L.push('Binary file changed on both sides. Not merged — yours kept.');
      }
      const prov = provenance(home, p.rel);
      if (prov) { L.push(''); L.push(`- your last change here: ${prov}`); }
      L.push('');
    });
  }

  const quiet = plan.filter((p) => ['updated', 'added', 'merged', 'removed'].includes(p.tier));
  if (quiet.length) {
    L.push('## Applied without question');
    L.push('');
    for (const p of quiet) L.push(`- \`${p.rel}\` — ${p.tier}`);
    L.push('');
  }

  if (links.length) {
    L.push('## Environments re-linked');
    L.push('');
    L.push('| env | linked | ejected | pruned |');
    L.push('| --- | ------ | ------- | ------ |');
    for (const l of links) L.push(`| ${l.name} | ${l.linked} | ${l.ejected || '—'} | ${l.pruned || '—'} |`);
    L.push('');
  }
  return L.join('\n');
}

module.exports = async function update(args) {
  const force = args.includes('--force');
  const home = paths.HOME;

  // --- refusals, all of them before any write ------------------------------
  if (!fs.existsSync(paths.manifestPath)) {
    throw new Error(`${home} has no .context-specs/manifest.json — not a vendored harness. Run 'context-specs init'.`);
  }
  const dirty = git(home, ['status', '--porcelain']);
  if (dirty === null) throw new Error(`${home} is not a git repository`);
  if (dirty !== '' && !force) {
    throw new Error(
      'the harness has uncommitted changes.\n' +
      '  update rewrites vendored files, and a clean tree is what makes `git checkout .` your undo.\n' +
      '  Commit or stash first.'
    );
  }
  for (const env of registry.load()) {
    let pid = null;
    try { pid = parseInt(fs.readFileSync(paths.pidFile(env.name), 'utf8'), 10); } catch {}
    if (pid && isPidAlive(pid)) {
      throw new Error(`supervisor for '${env.name}' is running (pid ${pid}) — stop it first: context-specs stop ${env.name}`);
    }
  }

  const m = vendor.readManifest(home);
  const from = m.version;
  const to = vendor.pkgVersion();
  if (from === to && !force) {
    console.log(`already at v${to} — nothing to update`);
    return;
  }
  if (!force && cmpVersion(to, from) < 0) {
    throw new Error(`installed CLI is v${to} but the harness is v${from} — refusing to downgrade (use --force)`);
  }

  // --- plan ----------------------------------------------------------------
  const baseRoot = paths.baseDir;
  const upstreamFiles = vendor.enumerate(paths.PKG);
  const plan = classify(home, paths.PKG, baseRoot, m.files || [], upstreamFiles);

  // --- apply ---------------------------------------------------------------
  // BASE advances per file, immediately after the working copy lands, so an
  // interrupted update is resumable rather than corrupt. It advances for
  // conflicts too: BASE means "what upstream last handed you", and the markers
  // live in the working file where the human and the skill can see them.
  const abortAfter = parseInt(process.env.CONTEXT_SPECS_ABORT_AFTER, 10); // test-only
  let applied = 0;
  for (const p of plan) {
    if (p.tier === 'unchanged') continue;
    const mode = vendor.modeOf(paths.PKG, p.rel);
    if (p.tier === 'removed') {
      vendor.remove(home, p.rel);
      vendor.remove(baseRoot, p.rel);
    } else if (p.bytes) {
      vendor.write(home, p.rel, p.bytes, mode);
      vendor.write(baseRoot, p.rel, vendor.read(paths.PKG, p.rel), mode);
    } else if (p.tier === 'local-deleted' || p.tier === 'removed-kept' || p.tier === 'added-collision' || p.tier === 'conflict-binary') {
      // Working copy deliberately untouched; BASE still advances so the next
      // update compares against what upstream actually shipped.
      const u = vendor.read(paths.PKG, p.rel);
      if (u) vendor.write(baseRoot, p.rel, u, mode); else vendor.remove(baseRoot, p.rel);
    }
    applied++;
    if (abortAfter && applied >= abortAfter) throw new Error(`aborted after ${applied} files (CONTEXT_SPECS_ABORT_AFTER)`);
  }

  // Manifest last: it is the commit point. Interrupted before this, the next
  // update re-derives and the already-applied files classify as `unchanged`.
  vendor.writeManifest(home, vendor.manifest(to, upstreamFiles));

  // --- re-link every environment -------------------------------------------
  // Not optional: gitignoreBlock() enumerates skill names, and pruneStale() is
  // the only thing that removes a symlink to a skill upstream just deleted.
  const links = [];
  for (const env of registry.load()) {
    if (!fs.existsSync(env.path)) continue;
    try {
      const { linked, agents, ejected, pruned } = linkEnv(env.path);
      ensureGitignore(env.path);
      links.push({ name: env.name, linked: linked.length + agents.length, ejected: ejected.length, pruned: pruned.length });
    } catch (e) {
      links.push({ name: env.name, linked: 0, ejected: 0, pruned: 0, error: e.message });
    }
  }

  fs.mkdirSync(paths.csDir, { recursive: true });
  fs.writeFileSync(paths.reportPath, report(home, from, to, plan, links));

  // --- report --------------------------------------------------------------
  const n = (t) => plan.filter((p) => p.tier === t).length;
  const bits = [
    [n('updated'), 'updated'], [n('added'), 'added'], [n('merged'), 'merged'],
    [n('merged-needs-review'), 'need review'], [n('conflict') + n('conflict-binary'), 'conflict'],
    [n('removed'), 'removed'], [n('local-deleted') + n('removed-kept') + n('added-collision'), 'kept'],
  ].filter(([c]) => c).map(([c, l]) => `${c} ${l}`);

  console.log(`Update applied: v${from} → v${to}`);
  console.log(`  ${bits.join(' · ') || 'no file changes'}`);
  for (const l of links) {
    console.log(`  re-linked '${l.name}': ${l.linked} links${l.pruned ? `, ${l.pruned} pruned` : ''}${l.ejected ? `, ${l.ejected} ejected` : ''}${l.error ? ` (error: ${l.error})` : ''}`);
  }
  console.log('');
  console.log(`Report: ${path.relative(home, paths.reportPath)} (in ${home})`);

  const attention = plan.filter((p) => ATTENTION.has(p.tier));
  if (attention.length) {
    console.log('');
    console.log(`Next: the Software 3.0 half. ${attention.length} file${attention.length === 1 ? '' : 's'} need a human decision:`);
    console.log('  claude');
    console.log(`  /update-harness --from ${from} --to ${to}`);
    console.log('');
    console.log("Review everything with 'git diff'; abort the whole update with 'git checkout .'.");
  } else {
    console.log('');
    console.log("Nothing needs review. Check it with 'git diff', then commit.");
  }
};

function cmpVersion(a, b) {
  const pa = String(a).split('.').map(Number), pb = String(b).split('.').map(Number);
  for (let i = 0; i < 3; i++) if ((pa[i] || 0) !== (pb[i] || 0)) return (pa[i] || 0) - (pb[i] || 0);
  return 0;
}
