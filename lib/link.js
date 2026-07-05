'use strict';
// The skill-delivery engine. Tier-1 skills reach an environment as SYMLINKS in
// its .claude/skills/ (gitignored — Claude Code follows skill-directory
// symlinks). Two callers:
//   - `context-specs add <env>` at registration time, and
//   - the deterministic header of the environment's bootstrap-worktree.sh for
//     every fresh worktree (gitignored symlinks do not materialize in new git
//     worktrees, so each one must be re-linked).
// Idempotent and fast by construction.
//
// Eject-by-shadowing: if the target already has a REAL directory (or file) of
// the same name, it is the project's own committed fork — skip it and report
// it as "ejected". Deleting the committed copy re-adopts the canonical skill on
// the next link.

const fs = require('fs');
const path = require('path');
const { skillsDir, subagentsDir } = require('./paths');

// /intent is NOT symlinked: it is a Software 3.0 artifact — /env-init copies it
// into the environment (verbatim or customized) as a committed, project-owned
// skill. It is one of the two developer-owned levers (with the Expert).
const EXCLUDED_SKILLS = new Set(['intent']);

// Enumerate canonical skills: skills/<group>/<name>/SKILL.md → flat <name>.
function canonicalSkills() {
  const out = [];
  for (const group of fs.readdirSync(skillsDir)) {
    const groupDir = path.join(skillsDir, group);
    if (!fs.statSync(groupDir).isDirectory()) continue;
    for (const name of fs.readdirSync(groupDir)) {
      const dir = path.join(groupDir, name);
      if (!EXCLUDED_SKILLS.has(name) && fs.existsSync(path.join(dir, 'SKILL.md'))) {
        out.push({ name, dir });
      }
    }
  }
  return out.sort((a, b) => a.name.localeCompare(b.name));
}

function canonicalAgents() {
  if (!fs.existsSync(subagentsDir)) return [];
  return fs.readdirSync(subagentsDir)
    .filter((f) => f.endsWith('.md'))
    .map((f) => ({ name: f, file: path.join(subagentsDir, f) }));
}

// Create/refresh one symlink; returns 'linked' | 'ejected'.
function ensureLink(target, linkPath) {
  let st = null;
  try { st = fs.lstatSync(linkPath); } catch {}
  if (st && !st.isSymbolicLink()) return 'ejected'; // real dir/file = project-owned fork
  if (st) fs.unlinkSync(linkPath); // stale/moved symlink: heal it
  fs.symlinkSync(target, linkPath);
  return 'linked';
}

function linkEnv(envPath) {
  const root = path.resolve(envPath);
  if (!fs.existsSync(root)) throw new Error(`no such directory: ${root}`);
  const skillsTarget = path.join(root, '.claude', 'skills');
  const agentsTarget = path.join(root, '.claude', 'agents');
  fs.mkdirSync(skillsTarget, { recursive: true });
  fs.mkdirSync(agentsTarget, { recursive: true });

  const linked = [];
  const ejected = [];
  for (const { name, dir } of canonicalSkills()) {
    const result = ensureLink(dir, path.join(skillsTarget, name));
    (result === 'linked' ? linked : ejected).push(name);
  }
  const agents = [];
  for (const { name, file } of canonicalAgents()) {
    const result = ensureLink(file, path.join(agentsTarget, name));
    (result === 'linked' ? agents : ejected).push(name);
  }
  return { linked, agents, ejected };
}

// The env-repo .gitignore entries for everything link creates. The block is
// marker-delimited so add can rewrite it idempotently.
const GITIGNORE_START = '# >>> context-specs (managed by `context-specs add` — do not edit inside markers) >>>';
const GITIGNORE_END = '# <<< context-specs <<<';

function gitignoreBlock() {
  const lines = [GITIGNORE_START];
  for (const { name } of canonicalSkills()) lines.push(`.claude/skills/${name}`);
  for (const { name } of canonicalAgents()) lines.push(`.claude/agents/${name}`);
  lines.push(GITIGNORE_END);
  return lines.join('\n');
}

function ensureGitignore(envPath) {
  const file = path.join(envPath, '.gitignore');
  const block = gitignoreBlock();
  let text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  const start = text.indexOf(GITIGNORE_START);
  const end = text.indexOf(GITIGNORE_END);
  if (start !== -1 && end !== -1) {
    text = text.slice(0, start) + block + text.slice(end + GITIGNORE_END.length);
  } else {
    text = text.replace(/\n*$/, text ? '\n\n' : '') + block + '\n';
  }
  fs.writeFileSync(file, text);
}

async function cli(args) {
  const target = args[0];
  if (!target) throw new Error('usage: context-specs link <path-to-repo-or-worktree>');
  const { linked, agents, ejected } = linkEnv(target);
  console.log(`linked ${linked.length} skills + ${agents.length} agents into ${path.resolve(target)}/.claude/`);
  if (ejected.length) console.log(`ejected (project-owned, left alone): ${ejected.join(', ')}`);
}

module.exports = { linkEnv, canonicalSkills, canonicalAgents, ensureGitignore, gitignoreBlock, cli, GITIGNORE_START, GITIGNORE_END };
