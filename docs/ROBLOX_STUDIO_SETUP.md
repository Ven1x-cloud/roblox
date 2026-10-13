# Roblox Studio koppelen — stap voor stap

## Wat zet je in Roblox?

**Alleen dit bestand** gaat in de lokale pluginmap van Roblox Studio:

```text
plugin/RobloxGitBridge.plugin.lua
```

Dit is een **Studio-plugin**, geen script van je game. Zet het niet onder `Workspace`, `ServerScriptService` of ergens anders in de Explorer. De bridge-bestanden en JSON-patches blijven in de repo op je computer.

> De repo bevat de bridge en het gameplan; nog niet de complete speelbare game. De plugin kan een place aanpassen, maar slaat/publiceert die place niet automatisch op Roblox op.

## Hoe de onderdelen samenwerken

- De Studio-plugin kijkt naar de geopende place en exporteert relevante objecten en, als **Scripts: AAN** staat, scriptbroncode.
- Het Node-programma (`npm start`) draait lokaal en schrijft exports in deze repo.
- De lokale bridge gebruikt je eigen Git-configuratie om commits naar `arena/777e60cb-roblox` te pushen. Er staat geen GitHub-token in de plugin.
- Nieuwe assistent-patches worden op diezelfde branch opgehaald; daarna kan de plugin ze automatisch in de open place toepassen.

## 1. Zorg voor de bijgewerkte lokale repo

Auto-sync werkt alleen vanuit een lokale Git-checkout van deze repo op branch `arena/777e60cb-roblox`.

Als je de repo al hebt, open een terminal in de repo-hoofdmap en werk hem bij:

```sh
git pull --ff-only origin arena/777e60cb-roblox
```

Je moet in die map `package.json`, `bridge/`, `plugin/` en `studio/` kunnen zien. Auto-sync commit **alle gewijzigde bestanden**. Controleer daarom eerst dat er geen geheimen of onverwachte bestanden klaarstaan. De meegeleverde `.gitignore` sluit gebruikelijke lokale credentials, keys en buildbestanden uit.

## 2. Installeer of vervang de Studio-plugin

1. Open Roblox Studio.
2. Kies **Plugins → Plugins Folder**. Studio opent de juiste pluginmap.
3. Kopieer vanuit de lokale repo `plugin/RobloxGitBridge.plugin.lua` naar die map. De naam moet eindigen op `.plugin.lua`, niet `.plugin.lua.txt`.
4. Sluit Roblox Studio volledig af en open het opnieuw.
5. Klik op **Roblox Git Bridge** in de Plugins-toolbar.

Als je de plugin al eerder had geïnstalleerd, vervang dan het oude bestand door deze bijgewerkte versie en herstart Studio.

## 3. Start de lokale bridge

1. Installeer Node.js 18 of hoger.
2. Open een terminal in de repo-hoofdmap — waar `package.json` staat — en voer uit:

   ```sh
   npm start
   ```

3. Laat de terminal open. De bridge toont een tijdelijke token en meldt of Auto Git aanstaat. De standaardinstelling is aan.
4. Als `npm` niet wordt herkend, installeer Node.js en open daarna een nieuwe terminal.

De bridge verwacht dat de lokale Git-branch `arena/777e60cb-roblox` heet en dat GitHub-authenticatie al via Git op je computer werkt. De plugin heeft geen GitHub-wachtwoord of GitHub-token nodig.

## 4. Verbind en controleer de automatische knoppen

1. Laat de URL staan op `http://127.0.0.1:47831`.
2. Plak de token uit de huidige terminal in het tokenveld.
3. Klik **Opslaan + testverbinding**.
4. Controleer dat de knoppen **Automatische wereldsync: AAN** en **AI-patches automatisch toepassen: AAN** tonen. Je kunt op elk van die knoppen klikken om die functie uit te zetten.
5. Als Studio toestemming vraagt om met de lokale bridge te verbinden, sta die lokale verbinding toe.

De token verandert normaal wanneer je de bridge stopt en opnieuw start. Gebruik dan de nieuwe token.

## 5. Wat gebeurt er automatisch?

### Studio → repo → GitHub

De plugin volgt wijzigingen in Workspace en belangrijke game-services, waaronder ReplicatedStorage, ServerScriptService, ServerStorage, StarterGui en StarterPlayer. Als er ongeveer drie seconden geen nieuwe wijziging is, exporteert hij die services naar `studio/snapshots/latest.json`.

De bridge haalt zo nodig nieuwe commits op met fast-forward-only, stage’t met `git add -A`, maakt een commit en pusht naar `origin arena/777e60cb-roblox`. Hij doet dat alleen als er daadwerkelijk repo-wijzigingen zijn. Dit kan dus **ook andere gewijzigde repo-bestanden** meenemen, niet alleen de snapshot.

Als de lokale branch verkeerd staat, de lokale en remote branches uiteenlopen of een remote update botst met on-gecommitte lokale wijzigingen, stopt de bridge en meldt hij dat. Hij force-pusht niet. De lokale snapshot kan dan wel opgeslagen zijn; corrigeer de branch/status en probeer daarna opnieuw.

### GitHub → Studio

De plugin controleert ongeveer iedere acht seconden op een nieuwe `studio/changes/latest.json`-patch. De bridge haalt de werkbranch fast-forward-only op. Bij een nieuwe patch-id past de plugin de operaties automatisch toe, zonder preview: objecten maken, properties wijzigen, scriptbroncode bijwerken en objecten verwijderen.

Gebruik voor iedere patch een **nieuwe id**. De plugin voorkomt dat dezelfde id opnieuw wordt toegepast. De knoppen **Wijzigingen bekijken** en **Voorbeeld toepassen** blijven beschikbaar; zet automatisch toepassen uit als je elke patch eerst wilt controleren.

> Automatisch toepassen verandert de place zonder bevestigingsklik. Scriptbroncode wordt niet met `loadstring` uitgevoerd, maar scripts kunnen wel gaan draaien wanneer de game start. Test op een kopie en sla je place zelf op in Studio. De plugin maakt undo-waypoints, maar vertrouw niet alleen op Undo.

## 6. Veilige test-obby (optioneel)

Doe dit op een test-place of een reservekopie.

1. Zet **AI-patches automatisch toepassen** tijdelijk uit als je eerst zelf wilt kijken.
2. Kopieer `studio/changes/latest.example.json` naar `studio/changes/latest.json`.
   - PowerShell vanuit de repo-hoofdmap: `Copy-Item studio/changes/latest.example.json studio/changes/latest.json`
   - macOS/Linux: `cp studio/changes/latest.example.json studio/changes/latest.json`
3. Met auto-apply uit: klik **Wijzigingen bekijken** en daarna eventueel **Voorbeeld toepassen**. Met auto-apply aan wordt de StarterObby-patch vanzelf toegepast zodra de lokale repo de nieuwe patch bevat.
4. Kijk in de Explorer onder Workspace en sla de test-place zelf op als je het resultaat wilt bewaren.

## Bestanden die je niet in Studio hoeft te plaatsen

| Pad | Betekenis |
|---|---|
| `bridge/server.mjs`, `bridge/protocol.mjs` | Lokale Node-server en validatie. |
| `package.json` | Start- en testcommando's. |
| `studio/changes/latest.json` | Patch die de plugin leest; geen Roblox-script. |
| `studio/changes/latest.example.json` | Kopieerbaar voorbeeld. |
| `studio/snapshots/latest.json` | Snapshot; geen Roblox-place of screenshot. |
| `studio/FORMAT.md` | Uitleg van het JSON-formaat. |
| `GAME_DESIGN.md` | Gameconcept en prototypeplan. |

## Automatisch Git uitzetten

In de plugin kun je automatische wereldsync uitzetten; daarmee stopt automatisch exporteren vanuit Studio. Om automatisch ophalen/committen/pushen in de lokale bridge uit te zetten, stop `npm start` met `Ctrl+C` en start hem opnieuw met:

PowerShell:

```powershell
$env:STUDIO_AUTO_GIT="0"
npm start
```

macOS/Linux:

```sh
STUDIO_AUTO_GIT=0 npm start
```

Met Auto Git uit blijven lokale snapshots en patches werken, maar de bridge haalt niet automatisch van GitHub op en pusht niets.

## Problemen oplossen

- **Plugin ontbreekt:** controleer dat het bestand in de map van **Plugins → Plugins Folder** staat, eindigt op `.plugin.lua`, en herstart Studio.
- **Verbinding geweigerd:** controleer dat `npm start` nog draait en de URL `http://127.0.0.1:47831` is.
- **HTTP 401:** plak de token uit de huidige bridge-terminal opnieuw.
- **Branch-melding:** voer `git status --short` en `git branch --show-current` uit in de repo. Auto Git pusht alleen `arena/777e60cb-roblox`; bij afwijkende of uiteenlopende branches stopt hij.
- **Auto-push mislukt:** controleer de statusmelding in de plugin en dat Git op je computer toegang heeft tot de repo. De bridge force-pusht nooit.
- **Patch komt niet in Studio:** controleer of auto-apply aanstaat, of de patch in `studio/changes/latest.json` staat en of de patch-id nieuw is.
- **Snapshot lijkt niet volledig:** auto-sync volgt de opgesomde services, maar is geen volledige `.rbxl`-export; Terrain-voxels en exacte geïmporteerde mesh-geometrie worden niet meegenomen.
