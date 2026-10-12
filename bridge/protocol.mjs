export const SCHEMA_VERSION = 1;

export const ALLOWED_CLASSES = new Set([
  "Model",
  "Folder",
  "Part",
  "SpawnLocation",
  "Script",
  "LocalScript",
  "ModuleScript",
  "PointLight",
  "SpotLight",
  "Attachment",
  "Decal",
  "Texture",
]);

const PROPERTY_TYPES = new Map([
  ["Anchored", "boolean"],
  ["CanCollide", "boolean"],
  ["CanTouch", "boolean"],
  ["CanQuery", "boolean"],
  ["CastShadow", "boolean"],
  ["Disabled", "boolean"],
  ["Enabled", "boolean"],
  ["Neutral", "boolean"],
  ["Shadows", "boolean"],
  ["Transparency", "number"],
  ["Reflectance", "number"],
  ["Brightness", "number"],
  ["Range", "number"],
  ["Angle", "number"],
  ["Duration", "number"],
  ["Size", "vector3"],
  ["Position", "vector3"],
  ["Orientation", "vector3"],
  ["Color", "color3"],
  ["Color3", "color3"],
  ["Material", "enum"],
  ["Shape", "enum"],
  ["Face", "enum"],
  ["Texture", "string"],
]);

const SCRIPT_CLASSES = new Set(["Script", "LocalScript", "ModuleScript"]);
const MAX_TREE_NODES = 3_000;
const MAX_SOURCE_CHARS = 2_000_000;
const MAX_OPERATIONS = 500;
const MAX_CREATE_DEPTH = 40;
const MAX_PATH_DEPTH = 80;

function fail(message) {
  throw new TypeError(message);
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function validateText(value, label, { max = 200, nonEmpty = false } = {}) {
  if (typeof value !== "string") fail(`${label} must be a string`);
  if (nonEmpty && value.trim().length === 0) fail(`${label} must not be empty`);
  if (value.length > max) fail(`${label} is too long (maximum ${max} characters)`);
  return value;
}

function validateNumber(value, label) {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    fail(`${label} must be a finite number`);
  }
}

function validateVector(value, label, color = false) {
  if (!Array.isArray(value) || value.length !== 3) {
    fail(`${label} must be an array of three numbers`);
  }
  value.forEach((item, index) => {
    validateNumber(item, `${label}[${index}]`);
    if (color && (item < 0 || item > 1)) {
      fail(`${label} color components must be between 0 and 1`);
    }
  });
}

function validateProperties(properties, label) {
  if (!isRecord(properties)) fail(`${label} must be an object`);
  const entries = Object.entries(properties);
  if (entries.length > 40) fail(`${label} has too many properties`);

  for (const [key, value] of entries) {
    const kind = PROPERTY_TYPES.get(key);
    if (!kind) fail(`${label}.${key} is not a supported property`);
    if (kind === "boolean" && typeof value !== "boolean") {
      fail(`${label}.${key} must be a boolean`);
    } else if (kind === "number") {
      validateNumber(value, `${label}.${key}`);
    } else if (kind === "vector3") {
      validateVector(value, `${label}.${key}`);
    } else if (kind === "color3") {
      validateVector(value, `${label}.${key}`, true);
    } else if (kind === "enum") {
      validateText(value, `${label}.${key}`, { max: 80, nonEmpty: true });
    } else if (kind === "string") {
      validateText(value, `${label}.${key}`, { max: 4_096 });
    }
  }
}

function validatePath(path, label) {
  if (!Array.isArray(path) || path.length === 0 || path.length > MAX_PATH_DEPTH) {
    fail(`${label} must be a non-empty array of path segments`);
  }

  path.forEach((segment, index) => {
    const at = `${label}[${index}]`;
    if (!isRecord(segment)) fail(`${at} must be an object`);
    validateText(segment.name, `${at}.name`, { max: 100, nonEmpty: true });
    validateText(segment.className, `${at}.className`, { max: 80, nonEmpty: true });
    if (!Number.isInteger(segment.ordinal) || segment.ordinal < 1) {
      fail(`${at}.ordinal must be a positive integer`);
    }
  });
}

function validateSnapshotNode(node, label, state, depth) {
  if (!isRecord(node)) fail(`${label} must be an object`);
  if (depth > MAX_PATH_DEPTH) fail(`${label} is nested too deeply`);
  state.nodes += 1;
  if (state.nodes > MAX_TREE_NODES) fail(`snapshot has more than ${MAX_TREE_NODES} instances`);

  validateText(node.name, `${label}.name`, { max: 100, nonEmpty: true });
  validateText(node.className, `${label}.className`, { max: 80, nonEmpty: true });
  validatePath(node.path, `${label}.path`);
  validateProperties(node.properties ?? {}, `${label}.properties`);

  if (node.source !== undefined) {
    if (!SCRIPT_CLASSES.has(node.className)) fail(`${label}.source is only valid for scripts`);
    if (typeof node.source !== "string") fail(`${label}.source must be a string`);
    state.sourceChars += node.source.length;
    if (state.sourceChars > MAX_SOURCE_CHARS) fail("snapshot contains too much script source");
  }

  if (node.children !== undefined && !Array.isArray(node.children)) {
    fail(`${label}.children must be an array`);
  }
  for (const [index, child] of (node.children ?? []).entries()) {
    validateSnapshotNode(child, `${label}.children[${index}]`, state, depth + 1);
  }
}

function validateCreateNode(node, label, state, depth) {
  if (!isRecord(node)) fail(`${label} must be an object`);
  if (depth > MAX_CREATE_DEPTH) fail(`${label} is nested too deeply`);
  state.createNodes += 1;
  if (state.createNodes > MAX_TREE_NODES) fail("change set creates too many instances");

  validateText(node.className, `${label}.className`, { max: 80, nonEmpty: true });
  if (!ALLOWED_CLASSES.has(node.className)) {
    fail(`${label}.className '${node.className}' is not supported`);
  }
  validateText(node.name, `${label}.name`, { max: 100, nonEmpty: true });
  validateProperties(node.properties ?? {}, `${label}.properties`);

  if (node.source !== undefined) {
    if (!SCRIPT_CLASSES.has(node.className)) fail(`${label}.source is only valid for scripts`);
    if (typeof node.source !== "string") fail(`${label}.source must be a string`);
    state.sourceChars += node.source.length;
    if (state.sourceChars > MAX_SOURCE_CHARS) fail("change set contains too much script source");
  }

  if (node.children !== undefined && !Array.isArray(node.children)) {
    fail(`${label}.children must be an array`);
  }
  for (const [index, child] of (node.children ?? []).entries()) {
    validateCreateNode(child, `${label}.children[${index}]`, state, depth + 1);
  }
}

export function validateSnapshot(snapshot) {
  if (!isRecord(snapshot)) fail("snapshot must be a JSON object");
  if (snapshot.schemaVersion !== SCHEMA_VERSION) fail(`snapshot schemaVersion must be ${SCHEMA_VERSION}`);
  if (!Array.isArray(snapshot.roots) || snapshot.roots.length > 100) {
    fail("snapshot.roots must be an array with at most 100 entries");
  }
  validateText(snapshot.exportedAt, "snapshot.exportedAt", { max: 80, nonEmpty: true });
  validateText(snapshot.placeName, "snapshot.placeName", { max: 100 });

  const state = { nodes: 0, sourceChars: 0 };
  snapshot.roots.forEach((node, index) => {
    validateSnapshotNode(node, `snapshot.roots[${index}]`, state, 1);
  });
  return { roots: snapshot.roots.length, instances: state.nodes, sourceChars: state.sourceChars };
}

export function validateChangeSet(changeSet) {
  if (!isRecord(changeSet)) fail("change set must be a JSON object");
  if (changeSet.schemaVersion !== SCHEMA_VERSION) {
    fail(`change set schemaVersion must be ${SCHEMA_VERSION}`);
  }
  validateText(changeSet.id, "change set.id", { max: 100, nonEmpty: true });
  if (!/^[A-Za-z0-9._-]+$/.test(changeSet.id)) {
    fail("change set.id may contain only letters, numbers, dots, underscores, and hyphens");
  }
  validateText(changeSet.summary, "change set.summary", { max: 500, nonEmpty: true });
  if (!Array.isArray(changeSet.operations) || changeSet.operations.length > MAX_OPERATIONS) {
    fail(`change set.operations must be an array with at most ${MAX_OPERATIONS} entries`);
  }

  const state = { createNodes: 0, sourceChars: 0 };
  changeSet.operations.forEach((operation, index) => {
    const label = `change set.operations[${index}]`;
    if (!isRecord(operation)) fail(`${label} must be an object`);

    if (operation.op === "create") {
      validatePath(operation.parent, `${label}.parent`);
      validateCreateNode(operation.node, `${label}.node`, state, 1);
    } else if (operation.op === "set") {
      validatePath(operation.path, `${label}.path`);
      validateProperties(operation.properties, `${label}.properties`);
    } else if (operation.op === "setSource") {
      validatePath(operation.path, `${label}.path`);
      if (typeof operation.source !== "string") fail(`${label}.source must be a string`);
      state.sourceChars += operation.source.length;
      if (state.sourceChars > MAX_SOURCE_CHARS) fail("change set contains too much script source");
    } else if (operation.op === "delete") {
      validatePath(operation.path, `${label}.path`);
    } else {
      fail(`${label}.op must be create, set, setSource, or delete`);
    }
  });

  return {
    id: changeSet.id,
    operations: changeSet.operations.length,
    createdInstances: state.createNodes,
    sourceChars: state.sourceChars,
  };
}
