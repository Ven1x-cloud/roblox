# Studio prototype scripts

These source files are installed into Roblox Studio by the active change set in `studio/changes/latest.json`:

- `PrototypeConfig.lua` → `ReplicatedStorage/BerumidaPrototypeConfig` (tuning constants shared by server/client).
- `ExpeditionClock.server.lua` → `ServerScriptService/ExpeditionClock` (configurable 3-minute day/night prototype clock; currently enabled in the lobby place for testing).
- `BerumidaLobbyHUD.client.lua` → `StarterPlayer/StarterPlayerScripts/BerumidaLobbyHUD` (safe lobby status/time HUD; no party, save, purchase, or teleport actions yet).

The lobby patch is a non-destructive greybox: it adds a named model and moves the existing default spawn; it does not delete user content. Scripts do not create passes, save data, teleport players, or implement the VIP revive yet.
