# Roblox Studio Git Bridge

Een eerste, veilige basis om een Roblox Studio-place via dit Git-repository met een AI-codeassistent te laten samenwerken. De bridge bestaat uit een lokale Studio-plugin en een klein Node.js-programma. De plugin exporteert een beschrijving van je wereld en scripts; de assistent kan daarna gewone bestanden in de repo aanpassen. Je bekijkt wijzigingen in Studio en past ze daar handmatig toe.

> **Belangrijk:** dit geeft de assistent geen live beeldscherm of directe toegang tot Roblox Studio. De plugin exporteert een JSON-snapshot met de objecten, posities, afmetingen, materialen, kleuren en (optioneel) scriptcode. Daarmee kan ik de structuur en code bekijken en bewerken. Een screenshot, terrein-data, de exacte geometrie van geïmporteerde meshes en willekeurige `.rbxm`-modellen worden nog niet overgezet.

## Wat zit erin?

- Een Studio-plugin met knoppen voor verbinden, Workspace/selectie exporteren, wijzigingen bekijken en wijzigingen toepassen.
- Een lokale HTTP-bridge die alleen op `127.0.0.1` luistert en met een tijdelijke token is beveiligd.
- Wereldexport naar `studio/snapshots/latest.json`.
- Een expliciet wijzigingsformaat voor Luau-broncode en eenvoudige 3D-bouwblokken: `Part`, `Model`, `Folder`, `SpawnLocation`, attachments, lichtbronnen en decals/textures.
- Tests voor de bridge- en JSON-formaten.

De plugin voert geen ontvangen tekst uit met `loadstring` of iets vergelijkbaars. Een `setSource`-wijziging schrijft alleen broncode naar een Script/LocalScript/ModuleScript; Roblox kan die code later wel uitvoeren als dat script in je spel wordt gestart. Lees scriptwijzigingen dus na voordat je ze toepast.

## Installeren

1. Installeer **Node.js 18 of hoger**.
2. Kopieer `plugin/RobloxGitBridge.plugin.lua` naar de pluginmap die Roblox Studio opent via **Plugins → Plugins Folder**. Herstart Studio als de plugin niet meteen verschijnt.
3. Open een terminal in de hoofdmap van deze repo en start de bridge:

   ```sh
   npm start
   ```

   De bridge print een tijdelijke token in de terminal. Laat dit proces draaien zolang je Studio synchroniseert. De bridge maakt geen Git-commit, pusht niets en merge’t niets.
4. Open **Roblox Studio → Plugins → Roblox Git Bridge**. Laat de URL op `http://127.0.0.1:47831` staan, plak de token in het tokenveld en druk op **Opslaan + testverbinding**.
5. Als Studio daarom vraagt, sta HTTP-verzoeken toe via **Game Settings → Security → Allow HTTP Requests**.
6. Klik op **Workspace exporteren** of selecteer eerst een kleiner deel van de wereld en klik op **Selectie exporteren**. De snapshot komt in `studio/snapshots/latest.json`.

De bridge is bedoeld voor een lokale checkout van deze repo. De plugin bevat geen GitHub-token en praat niet rechtstreeks met GitHub: hij verbindt met de lokale repo, waarna gewone Git-commando's de bestanden naar GitHub kunnen sturen. Commit en push de snapshot zelf wanneer je wilt dat die daar (en voor een latere assistent-sessie) beschikbaar is. Deel de bridge-token niet; de automatisch aangemaakte token vervalt wanneer je de bridge stopt. Na toepassen moet je je Roblox-place zelf opslaan/publiceren in Studio.

## Een wijziging terugzetten naar Studio

1. Vraag de assistent om een wijziging in deze repo te maken. Een patch staat in `studio/changes/latest.json`.
2. Zorg dat die patch in dezelfde lokale checkout staat (bijvoorbeeld door je repo bij te werken met Git).
3. Druk in Studio op **Wijzigingen bekijken**. Controleer de samenvatting.
4. Druk pas daarna op **Voorbeeld toepassen**. De plugin maakt Studio-undo-waypoints; bij problemen kun je direct in Studio ongedaan maken met **Ctrl+Z**.

Om de meegeleverde voorbeeld-obby te proberen, kopieer je `studio/changes/latest.example.json` naar `studio/changes/latest.json` en gebruik je **Wijzigingen bekijken** en **Voorbeeld toepassen**. Pas het voorbeeldbestand aan of vraag de assistent om iets anders te bouwen.

## Git-veiligheid

- De plugin stuurt alleen snapshots naar de lokale bridge; hij pusht niet naar GitHub.
- De bridge voert geen Git-commando's uit en heeft geen GitHub-credentials nodig.
- Er wordt nooit automatisch een PR aangemaakt, gemerged of gesloten. De branch en GitHub-acties blijven onder jouw controle.
- De plugin accepteert alleen de expliciete wijzigingsoperaties uit `studio/FORMAT.md`; er is geen willekeurige Lua-evaluatie.
- De standaardbridge bindt alleen aan `127.0.0.1`. Stel `STUDIO_BRIDGE_HOST` niet in op een publiek adres.

## Ontwikkelen en testen

```sh
npm test
```

Configuratie via omgevingsvariabelen:

- `STUDIO_BRIDGE_PORT` — standaard `47831`.
- `STUDIO_BRIDGE_TOKEN` — optioneel een eigen token van minimaal 24 tekens; anders maakt de bridge er bij het starten een aan.
- `STUDIO_GIT_DIR` — optioneel pad naar de lokale repo als je de bridge vanuit een andere checkout start.

Zie [studio/FORMAT.md](studio/FORMAT.md) voor de snapshot- en patchschema's en hun beperkingen.
