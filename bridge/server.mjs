import { execFile as execFileCallback } from "node:child_process";
import { createServer } from "node:http";
import { randomBytes, timingSafeEqual } from "node:crypto";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { validateChangeSet, validateSnapshot } from "./protocol.mjs";

const execFile = promisify(execFileCallback);
const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(process.env.STUDIO_GIT_DIR || join(here, ".."));
const host = process.env.STUDIO_BRIDGE_HOST || "127.0.0.1";
const port = Number.parseInt(process.env.STUDIO_BRIDGE_PORT || "47831", 10);
const maxBodyBytes = 8 * 1024 * 1024;
const configuredToken = process.env.STUDIO_BRIDGE_TOKEN;
const token = configuredToken || randomBytes(32).toString("hex");
const sessionBranch = "arena/777e60cb-roblox";
const autoGitFromEnvironment = !["0", "false", "off", "no"].includes(
  (process.env.STUDIO_AUTO_GIT || "true").toLowerCase(),
);
const remoteRefreshMs = 10_000;

if (!Number.isInteger(port) || port < 1 || port > 65_535) {
  throw new Error("STUDIO_BRIDGE_PORT must be a valid TCP port");
}
if (configuredToken && configuredToken.length < 24) {
  throw new Error("STUDIO_BRIDGE_TOKEN must contain at least 24 characters");
}

function sendJson(response, status, payload) {
  const body = JSON.stringify(payload);
  response.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
  });
  response.end(body);
}

function isAuthorized(request, expectedToken) {
  const header = request.headers.authorization;
  if (typeof header !== "string" || !header.startsWith("Bearer ")) return false;
  const supplied = Buffer.from(header.slice(7));
  const expected = Buffer.from(expectedToken);
  return supplied.length === expected.length && timingSafeEqual(supplied, expected);
}

async function readJsonBody(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > maxBodyBytes) {
      const error = new Error(`request body is larger than ${maxBodyBytes} bytes`);
      error.statusCode = 413;
      throw error;
    }
    chunks.push(chunk);
  }

  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    const error = new Error("request body must contain valid JSON");
    error.statusCode = 400;
    throw error;
  }
}

function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(",")}]`;
  if (value !== null && typeof value === "object") {
    const entries = Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`);
    return `{${entries.join(",")}}`;
  }
  return JSON.stringify(value);
}

function semanticSnapshot(snapshot) {
  const copy = { ...snapshot };
  delete copy.exportedAt;
  delete copy.receivedAt;
  return stableJson(copy);
}

async function writeSnapshot(snapshot, snapshotFilePath, snapshotsDirectory) {
  await mkdir(snapshotsDirectory, { recursive: true });
  try {
    const previous = JSON.parse(await readFile(snapshotFilePath, "utf8"));
    if (semanticSnapshot(previous) === semanticSnapshot(snapshot)) {
      return { changed: false };
    }
  } catch (error) {
    if (error.code !== "ENOENT" && !(error instanceof SyntaxError)) throw error;
  }

  const temporaryFile = `${snapshotFilePath}.${process.pid}.${randomBytes(4).toString("hex")}.tmp`;
  const output = JSON.stringify({ ...snapshot, receivedAt: new Date().toISOString() }, null, 2) + "\n";
  await writeFile(temporaryFile, output, { encoding: "utf8", mode: 0o600 });
  await rename(temporaryFile, snapshotFilePath);
  return { changed: true };
}

async function readChangeSet(changesFilePath) {
  const contents = await readFile(changesFilePath, "utf8");
  const changeSet = JSON.parse(contents);
  validateChangeSet(changeSet);
  return changeSet;
}

async function runGit(root, args) {
  try {
    const result = await execFile("git", args, {
      cwd: root,
      timeout: 60_000,
      maxBuffer: 2 * 1024 * 1024,
      env: { ...process.env, GIT_TERMINAL_PROMPT: "0" },
    });
    return {
      stdout: (result.stdout || "").trim(),
      stderr: (result.stderr || "").trim(),
    };
  } catch (error) {
    const detail = (error.stderr || error.stdout || error.message || "unknown git error").trim();
    const wrapped = new Error(`git ${args.join(" ")} failed: ${detail}`);
    wrapped.gitExitCode = error.code;
    throw wrapped;
  }
}

async function readGitBranch(root) {
  return (await runGit(root, ["branch", "--show-current"])).stdout;
}

async function readGitStatus(root) {
  return (await runGit(root, ["status", "--porcelain", "--untracked-files=normal"])).stdout;
}

async function syncTargetBranch(root) {
  const currentBranch = await readGitBranch(root);
  if (currentBranch !== sessionBranch) {
    throw new Error(`Auto-sync is restricted to '${sessionBranch}'; current branch is '${currentBranch || "detached"}'.`);
  }

  await runGit(root, [
    "fetch",
    "--quiet",
    "origin",
    `refs/heads/${sessionBranch}:refs/remotes/origin/${sessionBranch}`,
  ]);
  const relation = (await runGit(root, [
    "rev-list",
    "--left-right",
    "--count",
    `HEAD...refs/remotes/origin/${sessionBranch}`,
  ])).stdout;
  const [aheadText, behindText] = relation.split(/\s+/);
  const ahead = Number(aheadText);
  const behind = Number(behindText);

  if (ahead > 0 && behind > 0) {
    throw new Error("Local and GitHub branches have diverged. Auto-sync stopped; no merge or force-push was attempted.");
  }
  if (behind > 0) {
    const status = await readGitStatus(root);
    if (status) {
      throw new Error("GitHub has newer commits, but this local repo has uncommitted files. Auto fast-forward stopped to protect them.");
    }
    await runGit(root, ["merge", "--ff-only", `refs/remotes/origin/${sessionBranch}`]);
  }

  return { branch: sessionBranch, fastForwarded: behind > 0, ahead };
}

async function commitAndPushAll(root) {
  const currentBranch = await readGitBranch(root);
  if (currentBranch !== sessionBranch) {
    throw new Error(`Refusing to push: current branch must be '${sessionBranch}', not '${currentBranch || "detached"}'.`);
  }
  const before = await readGitStatus(root);
  if (!before) {
    return { ok: true, committed: false, pushed: false, branch: sessionBranch, message: "No repo changes to sync." };
  }

  await runGit(root, ["add", "-A"]);
  let stagedDiff;
  try {
    await runGit(root, ["diff", "--cached", "--quiet", "--exit-code"]);
    stagedDiff = false;
  } catch (error) {
    if (error.gitExitCode !== 1) throw error;
    stagedDiff = true;
  }
  if (!stagedDiff) {
    return { ok: true, committed: false, pushed: false, branch: sessionBranch, message: "No staged repo changes to sync." };
  }

  const commit = await runGit(root, ["commit", "-m", "Auto-sync Roblox Studio and repo changes"]);
  const push = await runGit(root, ["push", "origin", sessionBranch]);
  return {
    ok: true,
    committed: true,
    pushed: true,
    branch: sessionBranch,
    commit: commit.stdout,
    push: push.stderr || push.stdout || "Pushed successfully.",
  };
}

export function createBridgeServer(options = {}) {
  const root = resolve(options.root || repoRoot);
  const bridgeToken = options.token || token;
  const autoGitEnabled = options.autoGit ?? autoGitFromEnvironment;
  const snapshotsDir = join(root, "studio", "snapshots");
  const snapshotFile = join(snapshotsDir, "latest.json");
  const changesFile = join(root, "studio", "changes", "latest.json");
  const refreshInterval = options.remoteRefreshMs ?? remoteRefreshMs;
  let lastRemoteSyncAt = 0;
  let cachedRemoteSync = null;
  let gitQueue = Promise.resolve();

  function withGitLock(action) {
    const pending = gitQueue.then(action, action);
    gitQueue = pending.catch(() => {});
    return pending;
  }

  async function refreshRemote(force = false) {
    if (!autoGitEnabled) return { enabled: false, branch: sessionBranch };
    const now = Date.now();
    if (!force && cachedRemoteSync && now - lastRemoteSyncAt < refreshInterval) {
      if (cachedRemoteSync.error) throw new Error(cachedRemoteSync.error);
      return cachedRemoteSync.result;
    }

    lastRemoteSyncAt = now;
    try {
      const result = await syncTargetBranch(root);
      cachedRemoteSync = { result };
      return result;
    } catch (error) {
      cachedRemoteSync = { error: error.message };
      throw error;
    }
  }

  return createServer(async (request, response) => {
    const pathname = new URL(request.url || "/", "http://127.0.0.1").pathname;

    if (request.method === "GET" && pathname === "/health") {
      return sendJson(response, 200, {
        ok: true,
        service: "Roblox Studio Git Bridge",
        protocolVersion: 1,
        autoGitEnabled,
        branch: sessionBranch,
      });
    }

    const knownRoute =
      (request.method === "POST" && pathname === "/v1/snapshot") ||
      (request.method === "GET" && pathname === "/v1/changes");
    if (!knownRoute) return sendJson(response, 404, { error: "route not found" });
    if (!isAuthorized(request, bridgeToken)) return sendJson(response, 401, { error: "invalid or missing bridge token" });

    if (request.method === "POST" && pathname === "/v1/snapshot") {
      let snapshot;
      let stats;
      try {
        snapshot = await readJsonBody(request);
        stats = validateSnapshot(snapshot);
      } catch (error) {
        return sendJson(response, error.statusCode || 422, { error: error.message || "invalid snapshot" });
      }

      let remoteSync = { enabled: false, branch: sessionBranch };
      let syncError = null;
      if (autoGitEnabled) {
        try {
          remoteSync = await withGitLock(() => refreshRemote(true));
        } catch (error) {
          syncError = error.message;
        }
      }

      let saved;
      try {
        saved = await writeSnapshot(snapshot, snapshotFile, snapshotsDir);
      } catch (error) {
        return sendJson(response, 500, { error: error.message || "could not save snapshot" });
      }

      let git = { enabled: autoGitEnabled, ok: !syncError, committed: false, pushed: false, branch: sessionBranch };
      if (syncError) {
        git.error = syncError;
      } else if (autoGitEnabled) {
        try {
          git = { enabled: true, ...(await withGitLock(() => commitAndPushAll(root))) };
          lastRemoteSyncAt = Date.now();
          cachedRemoteSync = { result: { enabled: true, branch: sessionBranch, fastForwarded: false, ahead: 0 } };
        } catch (error) {
          git = { enabled: true, ok: false, branch: sessionBranch, error: error.message };
        }
      }

      return sendJson(response, 200, {
        ok: true,
        file: "studio/snapshots/latest.json",
        changed: saved.changed,
        ...stats,
        git,
        remoteSync,
      });
    }

    if (autoGitEnabled) {
      try {
        await withGitLock(() => refreshRemote(false));
      } catch (error) {
        return sendJson(response, 409, { error: `Automatic GitHub update stopped: ${error.message}` });
      }
    }

    try {
      const changeSet = await readChangeSet(changesFile);
      return sendJson(response, 200, changeSet);
    } catch (error) {
      if (error.code === "ENOENT") {
        return sendJson(response, 404, {
          error: "No change set exists yet. Add studio/changes/latest.json to this repository first.",
        });
      }
      return sendJson(response, 422, { error: error.message || "could not read change set" });
    }
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const server = createBridgeServer();
  server.listen(port, host, () => {
    console.log(`Roblox Studio Git Bridge listening at http://${host}:${port}`);
    console.log(`Repository: ${basename(repoRoot)}`);
    console.log(`Auto Git sync: ${autoGitFromEnvironment ? `enabled (commit/push ${sessionBranch})` : "disabled"}`);
    console.log(`Bridge token (paste into the Studio plugin; do not share): ${token}`);
    if (host !== "127.0.0.1" && host !== "localhost" && host !== "::1") {
      console.warn("WARNING: the bridge is bound beyond loopback. Keep the token private and use a firewall.");
    }
  });

  const shutdown = () => server.close(() => process.exit(0));
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}
