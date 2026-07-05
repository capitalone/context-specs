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
const { scriptsDir, logsDir, pidFile, binPath } = require('./paths');
const { isPidAlive } = require('./util');

const BUILD_SCRIPT = path.join(scriptsDir, 'poll-and-dispatch.sh');
const LEARN_SCRIPT = path.join(scriptsDir, 'learn-dispatch.sh');
const BACKOFF_CAP_S = 3600;

function targets(args) {
  if (args.includes('--all')) {
    const envs = registry.load().filter((e) => e.enabled !== false);
    if (!envs.length) throw new Error('no environments registered');
    return envs;
  }
  return [registry.resolveOne(args.find((a) => !a.startsWith('--')))];
}

function readPid(name) {
  try { return parseInt(fs.readFileSync(pidFile(name), 'utf8'), 10); } catch { return null; }
}

async function start(args) {
  for (const env of targets(args)) {
    const pid = readPid(env.name);
    if (pid && isPidAlive(pid)) {
      console.log(`${env.name}: supervisor already running (pid ${pid})`);
      continue;
    }
    fs.mkdirSync(logsDir(env.name), { recursive: true });
    const out = fs.openSync(path.join(logsDir(env.name), 'supervisor.log'), 'a');
    const child = spawn(process.execPath, [binPath, '__supervise', env.name], {
      detached: true,
      stdio: ['ignore', out, out],
    });
    child.unref();
    fs.writeFileSync(pidFile(env.name), String(child.pid));
    console.log(`${env.name}: supervisor started (pid ${child.pid}) — logs: context-specs logs ${env.name} -f`);
  }
}

async function stop(args) {
  for (const env of targets(args)) {
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
  const env = registry.resolveOne(args.find((a) => !a.startsWith('--')));
  const script = learn ? LEARN_SCRIPT : BUILD_SCRIPT;
  for (;;) {
    const { status } = spawnSync('bash', [script, env.path, env.name], { stdio: 'inherit' });
    if (status === 10) continue; // advanced — drain
    process.exit(status ?? 1);
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function tick(script, env, logFile) {
  return new Promise((resolve) => {
    const out = fs.openSync(logFile, 'a');
    fs.writeSync(out, `\n--- ${new Date().toISOString()} tick ---\n`);
    const child = spawn('bash', [script, env.path, env.name], { stdio: ['ignore', out, out] });
    child.on('exit', (code) => { fs.closeSync(out); resolve(code ?? 1); });
    child.on('error', () => { fs.closeSync(out); resolve(1); });
  });
}

// Hidden command the detached child runs. Two setTimeout-chain loops; SIGTERM
// exits cleanly (in-flight bash tick is left to finish its own flock-guarded
// work — the next supervisor simply takes over the schedule).
async function supervise(args) {
  const env = registry.resolveOne(args[0]);
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
    loop(BUILD_SCRIPT, 'build.log', interval, true),
    loop(LEARN_SCRIPT, 'learn.log', learnInterval, false),
  ]);
}

module.exports = { start, stop, runOnce, supervise };
