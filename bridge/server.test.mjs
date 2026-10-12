import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createBridgeServer } from "./server.mjs";

const token = "test-token-which-is-long-enough-123456";

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

test("bridge protects routes and reads/writes only the documented repo files", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "roblox-studio-bridge-"));
  const server = createBridgeServer({ root, token });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  t.after(async () => {
    server.closeAllConnections?.();
    await new Promise((resolve) => server.close(resolve));
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
