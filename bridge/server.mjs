import { createServer } from "node:http";
import { randomBytes, timingSafeEqual } from "node:crypto";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { validateChangeSet, validateSnapshot } from "./protocol.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(process.env.STUDIO_GIT_DIR || join(here, ".."));
const snapshotsDir = join(repoRoot, "studio", "snapshots");
const changesFile = join(repoRoot, "studio", "changes", "latest.json");
const snapshotFile = join(snapshotsDir, "latest.json");
const host = process.env.STUDIO_BRIDGE_HOST || "127.0.0.1";
const port = Number.parseInt(process.env.STUDIO_BRIDGE_PORT || "47831", 10);
const maxBodyBytes = 8 * 1024 * 1024;
const configuredToken = process.env.STUDIO_BRIDGE_TOKEN;
const token = configuredToken || randomBytes(32).toString("hex");

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

async function writeSnapshot(snapshot, snapshotFilePath, snapshotsDirectory) {
  await mkdir(snapshotsDirectory, { recursive: true });
  const temporaryFile = `${snapshotFilePath}.${process.pid}.${randomBytes(4).toString("hex")}.tmp`;
  const output = JSON.stringify({ ...snapshot, receivedAt: new Date().toISOString() }, null, 2) + "\n";
  await writeFile(temporaryFile, output, { encoding: "utf8", mode: 0o600 });
  await rename(temporaryFile, snapshotFilePath);
}

async function readChangeSet(changesFilePath) {
  const contents = await readFile(changesFilePath, "utf8");
  const changeSet = JSON.parse(contents);
  validateChangeSet(changeSet);
  return changeSet;
}

export function createBridgeServer(options = {}) {
  const root = resolve(options.root || repoRoot);
  const bridgeToken = options.token || token;
  const bridgeSnapshotsDir = join(root, "studio", "snapshots");
  const bridgeSnapshotFile = join(bridgeSnapshotsDir, "latest.json");
  const bridgeChangesFile = join(root, "studio", "changes", "latest.json");

  return createServer(async (request, response) => {
    const pathname = new URL(request.url || "/", "http://127.0.0.1").pathname;

    if (request.method === "GET" && pathname === "/health") {
      return sendJson(response, 200, {
        ok: true,
        service: "Roblox Studio Git Bridge",
        protocolVersion: 1,
      });
    }

    const knownRoute =
      (request.method === "POST" && pathname === "/v1/snapshot") ||
      (request.method === "GET" && pathname === "/v1/changes");
    if (!knownRoute) return sendJson(response, 404, { error: "route not found" });
    if (!isAuthorized(request, bridgeToken)) return sendJson(response, 401, { error: "invalid or missing bridge token" });

    if (request.method === "POST" && pathname === "/v1/snapshot") {
      try {
        const snapshot = await readJsonBody(request);
        const stats = validateSnapshot(snapshot);
        await writeSnapshot(snapshot, bridgeSnapshotFile, bridgeSnapshotsDir);
        return sendJson(response, 200, {
          ok: true,
          file: "studio/snapshots/latest.json",
          ...stats,
        });
      } catch (error) {
        const status = error.statusCode || 422;
        return sendJson(response, status, { error: error.message || "could not save snapshot" });
      }
    }

    try {
      const changeSet = await readChangeSet(bridgeChangesFile);
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
    console.log(`Repository: ${basename(repoRoot)} (snapshot target: studio/snapshots/latest.json)`);
    console.log(`Bridge token (paste into the Studio plugin; do not share): ${token}`);
    if (host !== "127.0.0.1" && host !== "localhost" && host !== "::1") {
      console.warn("WARNING: the bridge is bound beyond loopback. Keep the token private and use a firewall.");
    }
  });

  const shutdown = () => server.close(() => process.exit(0));
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}
