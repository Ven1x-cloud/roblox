import test from "node:test";
import assert from "node:assert/strict";
import { validateChangeSet, validateSnapshot } from "./protocol.mjs";

const workspacePath = [{ name: "Workspace", className: "Workspace", ordinal: 1 }];
const cloneWorkspacePath = () => workspacePath.map((segment) => ({ ...segment }));

function validSnapshot() {
  return {
    schemaVersion: 1,
    exportedAt: "2026-10-12T12:00:00.000Z",
    placeName: "Test place",
    roots: [
      {
        name: "Workspace",
        className: "Workspace",
        path: workspacePath,
        properties: {},
        children: [
          {
            name: "Ground",
            className: "Part",
            path: [...workspacePath, { name: "Ground", className: "Part", ordinal: 1 }],
            properties: {
              Anchored: true,
              Size: [40, 1, 40],
              Position: [0, 0, 0],
              Color: [0.2, 0.6, 0.3],
              Material: "Grass",
              Shape: "Block",
            },
            children: [],
          },
        ],
      },
    ],
  };
}

function validChangeSet() {
  return {
    schemaVersion: 1,
    id: "obby-v1",
    summary: "Add a grounded starter platform.",
    operations: [
      {
        op: "create",
        parent: cloneWorkspacePath(),
        node: {
          name: "Ground",
          className: "Part",
          properties: {
            Anchored: true,
            Size: [40, 1, 40],
            Position: [0, 0, 0],
            Color: [0.2, 0.6, 0.3],
            Material: "Grass",
            Shape: "Block",
          },
          children: [],
        },
      },
    ],
  };
}

test("accepts a supported scene snapshot", () => {
  assert.deepEqual(validateSnapshot(validSnapshot()), {
    roots: 1,
    instances: 2,
    sourceChars: 0,
  });
});

test("rejects an unsupported snapshot version", () => {
  const snapshot = validSnapshot();
  snapshot.schemaVersion = 99;
  assert.throws(() => validateSnapshot(snapshot), /schemaVersion/);
});

test("rejects invalid vector properties in snapshots", () => {
  const snapshot = validSnapshot();
  snapshot.roots[0].children[0].properties.Size = [1, 2];
  assert.throws(() => validateSnapshot(snapshot), /three numbers/);
});

test("accepts a model-building change set", () => {
  assert.deepEqual(validateChangeSet(validChangeSet()), {
    id: "obby-v1",
    operations: 1,
    createdInstances: 1,
    sourceChars: 0,
  });
});

test("rejects unsafe or unsupported instance classes", () => {
  const changeSet = validChangeSet();
  changeSet.operations[0].node.className = "DataModel";
  assert.throws(() => validateChangeSet(changeSet), /not supported/);
});

test("rejects code disguised as an instance property", () => {
  const changeSet = validChangeSet();
  changeSet.operations[0].node.properties.Source = "print('unexpected')";
  assert.throws(() => validateChangeSet(changeSet), /not a supported property/);
});

test("rejects malformed path ordinals", () => {
  const changeSet = validChangeSet();
  changeSet.operations[0].parent[0].ordinal = 0;
  assert.throws(() => validateChangeSet(changeSet), /positive integer/);
});

test("rejects change IDs that could be used as paths", () => {
  const changeSet = validChangeSet();
  changeSet.id = "../latest";
  assert.throws(() => validateChangeSet(changeSet), /only letters/);
});

test("accepts explicit script-source edits without evaluating them", () => {
  const changeSet = {
    schemaVersion: 1,
    id: "script-fix-01",
    summary: "Update the round-start module.",
    operations: [
      {
        op: "setSource",
        path: [
          ...workspacePath,
          { name: "RoundManager", className: "ModuleScript", ordinal: 1 },
        ],
        source: "return { started = true }",
      },
    ],
  };
  assert.equal(validateChangeSet(changeSet).sourceChars, 25);
});
