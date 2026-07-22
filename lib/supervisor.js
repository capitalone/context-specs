'use strict';
// The scheduler around the deterministic dispatcher. One detached supervisor
// process per environment, each running two independent loops:
//
//   build loop  — scripts/poll-and-dispatch.sh every INTERVAL (default 5m).
//                 Exit 10 ("advanced") → re-invoke IMMEDIATELY: real work drains
//                 at machine speed instead of waiting out the poll interval.
//                 Exit 0 ("idle") → sleep the interval. Anything else → error;
//                 exponential backoff, capped at 1h.
//   learn loop  — scripts/learn-dispatch.sh every LEARN_INTERVAL (default 10m).
//                 Never drains: after a run, the open learn/<sha> PR pauses it.
//
// The supervisor contains no decisions about WHAT to run — the dispatcher's
// exit code is the entire protocol. Intervals come from env vars INTERVAL /
// LEARN_INTERVAL (seconds) or a per-env `interval` in environments.toml.

const fs = require('fs');
const path = require('path');
const { spawn, spawnSync } = require('child_process');
const registry = require('./registry');
// scriptsDir/HOME are getters that resolve the harness lazily — see lib/paths.js.
// The dispatchers run from the harness's VENDORED scripts/, not the package's.
const paths = require('./paths');
const { logsDir, pidFile } = require('./paths');
const { isPidAlive } = require('./util');
const { selectTargets, selectOne } = require('./target');

const buildScript = () => path.join(paths.scriptsDir, 'poll-and-dispatch.sh');
const learnScript = () => path.join(paths.scriptsDir, 'learn-dispatch.sh');
const BACKOFF_CAP_S = 3600;

// Half of the agreement rule: node knows HOME, so node tells bash. Without this
// the dispatchers would self-derive a root that can differ from ours, splitting
// state/ — node writing supervisor.pid to one root while bash writes tick.lock
// to another, which silently breaks the flock that serializes ticks.
function harnessEnv() {
  return { ...process.env, CONTEXT_SPECS_HOME: paths.HOME };
}

// Resolve the targets and announce anything that was inferred (stderr — see
// lib/target.js).
function targets(args, command) {
  const { envs, notice } = selectTargets(args, { allowAll: true, command });
  if (notice) console.error(notice);
  return envs;
}

function readPid(name) {
  try { return parseInt(fs.readFileSync(pidFile(name), 'utf8'), 10); } catch { return null; }
}

async function start(args) {
  for (const env of targets(args, 'start')) {
    const pid = readPid(env.name);
    if (pid && isPidAlive(pid)) {
      console.log(`${env.name}: supervisor already running (pid ${pid})`);
      continue;
    }
    fs.mkdirSync(logsDir(env.name), { recursive: true });
    const out = fs.openSync(path.join(logsDir(env.name), 'supervisor.log'), 'a');
    // cwd + CONTEXT_SPECS_HOME are explicit: this child outlives the shell that
    // launched it by days, so it must not depend on the launcher's cwd (which
    // the user will have long since left, or deleted).
    const child = spawn(process.execPath, [paths.pkgBinPath, '__supervise', env.name], {
      detached: true,
      cwd: paths.HOME,
      env: harnessEnv(),
      stdio: ['ignore', out, out],
    });
    child.unref();
    fs.writeFileSync(pidFile(env.name), String(child.pid));
    console.log(`${env.name}: supervisor started (pid ${child.pid}) — logs: context-specs logs ${env.name} -f`);
  }
}

async function stop(args) {
  for (const env of targets(args, 'stop')) {
    const pid = readPid(env.name);
    if (!pid || !isPidAlive(pid)) {
      console.log(`${env.name}: not running`);
      try { fs.unlinkSync(pidFile(env.name)); } catch {}
      continue;
    }
    process.kill(pid, 'SIGTERM');
    const deadline = Date.now() + 10_000;
    while (isPidAlive(pid) && Date.now() < deadline) await sleep(200);
    if (isPidAlive(pid)) process.kill(pid, 'SIGKILL');
    try { fs.unlinkSync(pidFile(env.name)); } catch {}
    console.log(`${env.name}: stopped`);
  }
}

// `run` — one FOREGROUND pass, drained to idle, then exit. No daemon: keeps
// re-invoking the tick while it reports "advanced" (10), stops at idle (0),
// propagates errors. The interactive way to watch the harness work.
async function runOnce(args) {
  const learn = args.includes('--learn');
  // allowAll:false — `run` drains one environment in the foreground. Today
  // `--all` is silently swallowed here and the sole/default env runs instead.
  const { env } = selectOne(args, { allowAll: false, command: 'run' });
  const script = learn ? learnScript() : buildScript();
  for (;;) {
    const { status } = spawnSync('bash', [script, env.path, env.name], {
      cwd: paths.HOME, env: harnessEnv(), stdio: 'inherit',
    });
    if (status === 10) continue; // advanced — drain
    process.exit(status ?? 1);
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function tick(script, env, logFile) {
  return new Promise((resolve) => {
    const out = fs.openSync(logFile, 'a');
    fs.writeSync(out, `\n--- ${new Date().toISOString()} tick ---\n`);
    const child = spawn('bash', [script, env.path, env.name], {
      cwd: paths.HOME, env: harnessEnv(), stdio: ['ignore', out, out],
    });
    child.on('exit', (code) => { fs.closeSync(out); resolve(code ?? 1); });
    child.on('error', () => { fs.closeSync(out); resolve(1); });
  });
}

// Hidden command the detached child runs. Two setTimeout-chain loops; SIGTERM
// exits cleanly (in-flight bash tick is left to finish its own flock-guarded
// work — the next supervisor simply takes over the schedule).
async function supervise(args) {
  // Internal only — always spawned with an explicit name by `start` above, so
  // no inference and no sole-env fallback.
  const env = registry.find(args[0]);
  if (!env) throw new Error(`no environment named '${args[0]}'`);
  const interval = (parseInt(process.env.INTERVAL, 10) || parseInt(env.interval, 10) || 300) * 1000;
  const learnInterval = (parseInt(process.env.LEARN_INTERVAL, 10) || 600) * 1000;
  const logs = logsDir(env.name);
  fs.mkdirSync(logs, { recursive: true });
  console.log(`[supervisor] ${env.name}: build every ${interval / 1000}s (drain on advance), learn every ${learnInterval / 1000}s`);

  let running = true;
  process.on('SIGTERM', () => { running = false; process.exit(0); });
  process.on('SIGINT', () => { running = false; process.exit(0); });

  const loop = async (script, logName, base, drain) => {
    let backoff = base;
    while (running) {
      const code = await tick(script, env, path.join(logs, logName));
      if (code === 10 && drain) { backoff = base; continue; }
      if (code === 0) backoff = base;
      else {
        backoff = Math.min(backoff * 2, BACKOFF_CAP_S * 1000);
        console.log(`[supervisor] ${env.name}: ${logName} tick exited ${code}; backing off ${backoff / 1000}s`);
      }
      await sleep(backoff);
    }
  };

  await Promise.all([
    loop(buildScript(), 'build.log', interval, true),
    loop(learnScript(), 'learn.log', learnInterval, false),
  ]);
}

module.exports = { start, stop, runOnce, supervise };
