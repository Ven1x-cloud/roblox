import test from "node:test";
import assert from "node:assert/strict";
import { execFile as execFileCallback } from "node:child_process";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { createBridgeServer } from "./server.mjs";

const execFile = promisify(execFileCallback);
const token = "test-token-which-is-long-enough-123456";
const sessionBranch = "arena/777e60cb-roblox";

function snapshotFixture() {
  const path = [{ name: "Workspace", className: "Workspace", ordinal: 1 }];
  return {
    schemaVersion: 1,
    exportedAt: "2026-10-12T12:00:00.000Z",
    placeName: "Bridge test",
    roots: [
      {
        name: "Workspace",
        className: "Workspace",
        path,
        properties: {},
        children: [],
      },
    ],
  };
}

function changeSetFixture() {
  return {
    schemaVersion: 1,
    id: "test-01",
    summary: "Add a part.",
    operations: [
      {
        op: "create",
        parent: [{ name: "Workspace", className: "Workspace", ordinal: 1 }],
        node: {
          name: "Part",
          className: "Part",
          properties: { Anchored: true, Size: [4, 1, 4] },
        },
      },
    ],
  };
}

async function runGit(cwd, args) {
  const result = await execFile("git", args, { cwd, timeout: 30_000 });
  return (result.stdout || "").trim();
}

function startServer(server) {
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
}

function stopServer(server) {
  server.closeAllConnections?.();
  return new Promise((resolve) => server.close(resolve));
}

test("bridge protects routes and reads/writes only the documented repo files", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "roblox-studio-bridge-"));
  const server = createBridgeServer({ root, token, autoGit: false });
  await startServer(server);
  t.after(async () => {
    await stopServer(server);
    await rm(root, { recursive: true, force: true });
  });

  const address = server.address();
  const baseUrl = `http://127.0.0.1:${address.port}`;
  const headers = { Authorization: `Bearer ${token}`, "Content-Type": "application/json" };

  const health = await fetch(`${baseUrl}/health`);
  assert.equal(health.status, 200);
  assert.equal((await health.json()).ok, true);

  const unauthorized = await fetch(`${baseUrl}/v1/changes`);
  assert.equal(unauthorized.status, 401);

  const missingPatch = await fetch(`${baseUrl}/v1/changes`, { headers });
  assert.equal(missingPatch.status, 404);

  const snapshotResponse = await fetch(`${baseUrl}/v1/snapshot`, {
    method: "POST",
    headers,
    body: JSON.stringify(snapshotFixture()),
  });
  assert.equal(snapshotResponse.status, 200);
  assert.equal((await snapshotResponse.json()).instances, 1);

  const savedSnapshot = JSON.parse(await readFile(join(root, "studio/snapshots/latest.json"), "utf8"));
  assert.equal(savedSnapshot.placeName, "Bridge test");
  assert.equal(typeof savedSnapshot.receivedAt, "string");

  await mkdir(join(root, "studio/changes"), { recursive: true });
  const patch = changeSetFixture();
  await writeFile(join(root, "studio/changes/latest.json"), JSON.stringify(patch));
  const patchResponse = await fetch(`${baseUrl}/v1/changes`, { headers });
  assert.equal(patchResponse.status, 200);
  assert.deepEqual(await patchResponse.json(), patch);

  const invalidSnapshot = await fetch(`${baseUrl}/v1/snapshot`, {
    method: "POST",
    headers,
    body: JSON.stringify({ schemaVersion: 99 }),
  });
  assert.equal(invalidSnapshot.status, 422);
});

test("auto Git sync commits all repo changes, pushes only the session branch, and fast-forwards patches", async (t) => {
  const temporaryRoot = await mkdtemp(join(tmpdir(), "roblox-auto-git-"));
  const remote = join(temporaryRoot, "origin.git");
  const root = join(temporaryRoot, "local");
  const writer = join(temporaryRoot, "writer");
  await mkdir(root, { recursive: true });

  await runGit(temporaryRoot, ["init", "--quiet", "--bare", remote]);
  await runGit(temporaryRoot, ["init", "--quiet", "-b", sessionBranch, root]);
  await runGit(root, ["config", "user.name", "Studio Bridge Test"]);
  await runGit(root, ["config", "user.email", "studio-bridge-test@example.invalid"]);
  await writeFile(join(root, "README.md"), "test repo\n");
  await runGit(root, ["add", "README.md"]);
  await runGit(root, ["commit", "--quiet", "-m", "initial commit"]);
  await runGit(root, ["remote", "add", "origin", remote]);
  await runGit(root, ["push", "--quiet", "--set-upstream", "origin", sessionBranch]);

  const server = createBridgeServer({ root, token, autoGit: true, remoteRefreshMs: 0 });
  await startServer(server);
  t.after(async () => {
    await stopServer(server);
    await rm(temporaryRoot, { recursive: true, force: true });
  });

  const address = server.address();
  const baseUrl = `http://127.0.0.1:${address.port}`;
  const headers = { Authorization: `Bearer ${token}`, "Content-Type": "application/json" };
  await writeFile(join(root, "notes.txt"), "An unrelated repo change is included by the requested all-files sync.\n");

  const response = await fetch(`${baseUrl}/v1/snapshot`, {
    method: "POST",
    headers,
    body: JSON.stringify(snapshotFixture()),
  });
  assert.equal(response.status, 200);
  const result = await response.json();
  assert.equal(result.git.ok, true);
  assert.equal(result.git.committed, true);
  assert.equal(result.git.pushed, true);

  const pushedSnapshot = await runGit(temporaryRoot, [
    "--git-dir",
    remote,
    "show",
    `refs/heads/${sessionBranch}:studio/snapshots/latest.json`,
  ]);
  assert.equal(JSON.parse(pushedSnapshot).placeName, "Bridge test");
  assert.match(
    await runGit(temporaryRoot, ["--git-dir", remote, "show", `refs/heads/${sessionBranch}:notes.txt`]),
    /all-files sync/,
  );

  await runGit(temporaryRoot, ["clone", "--quiet", "--branch", sessionBranch, remote, writer]);
  await runGit(writer, ["config", "user.name", "Studio Bridge Test"]);
  await runGit(writer, ["config", "user.email", "studio-bridge-test@example.invalid"]);
  await mkdir(join(writer, "studio/changes"), { recursive: true });
  const patch = changeSetFixture();
  await writeFile(join(writer, "studio/changes/latest.json"), JSON.stringify(patch, null, 2));
  await runGit(writer, ["add", "studio/changes/latest.json"]);
  await runGit(writer, ["commit", "--quiet", "-m", "assistant patch"]);
  await runGit(writer, ["push", "--quiet", "origin", sessionBranch]);

  const patchResponse = await fetch(`${baseUrl}/v1/changes`, { headers });
  assert.equal(patchResponse.status, 200);
  assert.deepEqual(await patchResponse.json(), patch);
  assert.equal(await runGit(root, ["status", "--porcelain"]), "");
});
