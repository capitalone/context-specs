'use strict';
// The copy engine. `init` vendors the package's canonical content into a
// harness; `update` 3-way merges a newer package version against it.
//
// Two copies of every vendored file live in the harness:
//   <harness>/<rel>                     the working copy — the user edits this
//   <harness>/.context-specs/base/<rel> BASE — pristine, what was last vendored
//
// BASE is what makes a real 3-way merge possible. Keeping it on disk rather than
// re-deriving it from the version ref means update works offline, survives a
// yanked version, works for unpublished dev builds (the test suite depends on
// that), is readable directly by /update-harness, and — because it is written
// per-file as each file lands — survives an interrupted update.
//
// It also removes any need for hashing: with BASE present, "did the user edit
// this?" is a byte comparison, which keeps the CLI zero-dependency.

const fs = require('fs');
const path = require('path');
const paths = require('./paths');

const SKIP = new Set(['.DS_Store', 'node_modules', '.git']);

// Every vendored file, as sorted harness-relative POSIX paths.
function enumerate(root) {
  const out = [];
  const walk = (dir, rel) => {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir).sort()) {
      if (SKIP.has(entry)) continue;
      const abs = path.join(dir, entry);
      const r = rel ? `${rel}/${entry}` : entry;
      const st = fs.lstatSync(abs);
      if (st.isDirectory()) walk(abs, r);
      else if (st.isFile()) out.push(r);
    }
  };
  for (const top of paths.VENDORED) walk(path.join(root, top), top);
  return out.sort();
}

function read(root, rel) {
  try { return fs.readFileSync(path.join(root, rel)); } catch { return null; }
}

// Write preserving the executable bit. doctor.js MISSes if the dispatchers are
// not +x, and npm tarballs do carry the mode through.
function write(root, rel, buf, mode) {
  const dest = path.join(root, rel);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, buf);
  if (mode !== undefined) fs.chmodSync(dest, mode);
}

function modeOf(root, rel) {
  try { return fs.statSync(path.join(root, rel)).mode & 0o777; } catch { return undefined; }
}

function remove(root, rel) {
  try { fs.unlinkSync(path.join(root, rel)); } catch {}
  // Prune directories that the removal just emptied, up to the vendored top.
  let dir = path.dirname(path.join(root, rel));
  const stop = path.resolve(root);
  while (path.resolve(dir) !== stop) {
    try { if (fs.readdirSync(dir).length) break; fs.rmdirSync(dir); } catch { break; }
    dir = path.dirname(dir);
  }
}

// NUL sniff. Everything shipped today is text, but a future binary skill asset
// must never be fed to `git merge-file`, which would corrupt it silently.
function isText(buf) {
  return buf ? !buf.subarray(0, 8000).includes(0) : true;
}

function manifest(version, files) {
  return {
    manifestVersion: 1,
    version,
    vendoredAt: new Date().toISOString(),
    files,
  };
}

function readManifest(home) {
  return JSON.parse(fs.readFileSync(path.join(home, '.context-specs', 'manifest.json'), 'utf8'));
}

function writeManifest(home, m) {
  const p = path.join(home, '.context-specs', 'manifest.json');
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(m, null, 2) + '\n');
}

function pkgVersion() {
  return require(path.join(paths.PKG, 'package.json')).version;
}

// Fresh vendor of every canonical file into a new harness: working copy + BASE.
function vendorAll(pkgRoot, home) {
  const files = enumerate(pkgRoot);
  const base = path.join(home, '.context-specs', 'base');
  for (const rel of files) {
    const buf = read(pkgRoot, rel);
    const mode = modeOf(pkgRoot, rel);
    write(home, rel, buf, mode);
    write(base, rel, buf, mode);
  }
  writeManifest(home, manifest(pkgVersion(), files));
  return files;
}

module.exports = {
  enumerate, read, write, modeOf, remove, isText,
  manifest, readManifest, writeManifest, pkgVersion, vendorAll,
};
