# In Roblox Studio zetten — stap voor stap

Dit is de praktische uitleg voor het huidige repo. **Je hoeft maar één bestand in de pluginmap van Roblox Studio te zetten:**

```text
plugin/RobloxGitBridge.plugin.lua
```

> Dit bestand is een **Studio-plugin**, geen script voor je spel. Zet het dus niet in `Workspace`, `ServerScriptService`, `StarterPlayerScripts` of een andere plek in de Explorer. De huidige repo bevat nog geen complete speelbare game; de plugin is het gereedschap waarmee we later je Studio-place met de repo kunnen uitwisselen.

## Eerst het verschil tussen de twee dingen

- **Roblox Studio** is de editor waarin je place openstaat. De plugin verschijnt in de Studio-toolbar en kan de place die je op dat moment open hebt uitlezen of aanpassen.
- **De lokale bridge** is een klein programma dat op je eigen computer draait. Het schrijft exports naar de lokale kopie van deze Git-repo en leest er wijzigingspatches uit.
- **GitHub** is de online kopie. De plugin pusht daar niet rechtstreeks naartoe en bevat geen GitHub-token. Jij gebruikt Git om wijzigingen naar GitHub te sturen of daarvandaan op te halen.

## 1. Open de juiste repo-map op je computer

Je hebt een lokale kopie/checkout van deze repo nodig. Open die map in Verkenner/Finder en controleer dat je `package.json` en de mappen `plugin`, `bridge` en `studio` ziet.

Als je met Git werkt: gebruik de branch die je voor dit project gebruikt. De bridge kiest zelf geen branch en voert geen Git-commando's uit.

## 2. Installeer de plugin in Roblox Studio

1. Open Roblox Studio.
2. Kies **Plugins → Plugins Folder**. Studio opent dan de pluginmap van déze installatie.
3. Kopieer vanuit je repo alleen `plugin/RobloxGitBridge.plugin.lua` naar die map. Laat de bestandsnaam eindigen op `.plugin.lua`; controleer op Windows dat hij niet per ongeluk `RobloxGitBridge.plugin.lua.txt` heet.
4. Sluit Roblox Studio helemaal af en open het opnieuw.
5. Kijk op de **Plugins**-toolbar naar **Roblox Git Bridge**. Klik erop om het pluginvenster te openen.

De pluginmap is niet de Explorer van je spel. Je installeert het gereedschap voor Studio, niet een object in je place.

## 3. Start de lokale bridge

1. Open een terminal in de repo-hoofdmap — dezelfde map waar `package.json` staat.
2. Voer uit:

   ```sh
   npm start
   ```

   Er is geen `npm install` nodig; deze bridge gebruikt alleen Node.js zelf. Je hebt Node.js versie 18 of hoger nodig.
3. Laat de terminal open. Je ziet ongeveer:

   ```text
   Roblox Studio Git Bridge listening at http://127.0.0.1:47831
   Bridge token (paste into the Studio plugin; do not share): ...
   ```

   Kopieer de token uit jouw terminal. Gebruik niet de voorbeeldtekst hierboven. Deel de token niet. Als je de bridge stopt en opnieuw start, wordt er standaard een nieuwe token gemaakt.

## 4. Verbind de plugin

1. Laat de URL in de plugin staan op `http://127.0.0.1:47831`.
2. Plak de token in het tokenveld.
3. Klik op **Opslaan + testverbinding**.
4. Als Studio een netwerktoestemming vraagt, sta dan alleen de verbinding met deze lokale bridge toe. De plugin hoort niet naar een openbare server te wijzen.

Als je geen verbinding krijgt: controleer dat `npm start` nog draait en dat je de token van de huidige sessie hebt gekopieerd. Zie ook [Problemen oplossen](#problemen-oplossen).

## 5. Een eerste veilige test

Doe dit eerst op een nieuwe/test-place of maak een reservekopie van je place.

1. Open de place die je wilt testen.
2. Start `npm start` en verbind de plugin.
3. Kopieer in de repo `studio/changes/latest.example.json` en noem de kopie `studio/changes/latest.json`.
   - In Verkenner/Finder: kopieer het bestand en hernoem de kopie.
   - In PowerShell, vanuit de repo-hoofdmap:

     ```powershell
     Copy-Item studio/changes/latest.example.json studio/changes/latest.json
     ```

   - In macOS/Linux-terminal:

     ```sh
     cp studio/changes/latest.example.json studio/changes/latest.json
     ```
4. Klik in de plugin op **Wijzigingen bekijken**. De patch hoort aan te geven dat er een `StarterObby`-model met een basis, platform, startpunt en lamp wordt toegevoegd.
5. Alleen als je het goed vindt: klik op **Voorbeeld toepassen**.
6. Kijk in de Explorer onder `Workspace`. Als je tevreden bent, sla de place zelf op via Studio. De plugin publiceert je place niet automatisch.

Het JSON-bestand zelf wordt niet in Studio ingevoegd. De plugin leest dat bestand via de bridge en maakt de beschreven objecten in de open place.

## 6. Je eigen wereld bekijken of wijzigingen toepassen

### Een beschrijving van de wereld exporteren

- **Workspace exporteren** neemt de Workspace-hiërarchie mee. Een grote wereld kan de limiet bereiken; exporteer dan liever een kleinere selectie.
- Voor een kleiner deel: selecteer een Model of objecten in de Explorer/wereld en klik op **Selectie exporteren**.
- De export wordt lokaal aangemaakt als `studio/snapshots/latest.json`. Een nieuwe export vervangt dit `latest`-bestand.
- Met **Scripts: AAN** gaat leesbare broncode van scripts mee; met **Scripts: UIT** worden scriptbronnen overgeslagen.

De snapshot is bedoeld om de structuur en ondersteunde eigenschappen te bekijken. Het is geen screenshot en ook geen volledige `.rbxl`-back-up.

### Een wijziging laten maken

Vraag de assistent om een wijziging aan `studio/changes/latest.json` te maken. Zorg dat het bijgewerkte bestand in dezelfde lokale repo staat als de bridge. Klik in Studio op **Wijzigingen bekijken**, lees de samenvatting en klik daarna pas op **Voorbeeld toepassen**.

De plugin past expliciete bouw- en scriptwijzigingen toe. Hij gebruikt geen `loadstring` om willekeurige code uit te voeren. Wel kan een Script dat is aangepast later door Roblox worden uitgevoerd wanneer je de game start, dus controleer scriptcode eerst. Als een patch halverwege een fout krijgt, kunnen eerdere operaties al zijn toegepast; maak daarom vooraf een place-kopie en gebruik zo nodig Studio-undo (`Ctrl+Z`).

## Welke repo-bestanden zijn voor Roblox?

| Pad | Rol | In Roblox zetten? |
|---|---|---|
| `plugin/RobloxGitBridge.plugin.lua` | De lokale Studio-plugin. | **Ja**, in de Studio-pluginmap. |
| `bridge/server.mjs` en `bridge/protocol.mjs` | De lokale HTTP-server en validatie. | Nee; Node.js draait deze op je computer. |
| `package.json` | Bevat het commando `npm start` en `npm test`. | Nee. |
| `studio/changes/latest.json` | De patch die de plugin kan bekijken/toepassen. | Nee; de plugin leest hem uit de repo. |
| `studio/changes/latest.example.json` | Een testpatch om mee te beginnen. | Nee; kopieer hem eerst naar `latest.json`. |
| `studio/snapshots/latest.json` | Wereldbeschrijving die door exporteren wordt aangemaakt. | Nee; deze gaat in de repo, niet in je place. |
| `studio/FORMAT.md` | Uitleg van de JSON-formaten. | Nee. |
| `GAME_DESIGN.md` | De gamevisie en prototypeplanning. | Nee. |

## GitHub en Git

De plugin schrijft alleen naar de lokale checkout. Om een snapshot op GitHub te krijgen, moet je die zelf met Git committen en naar jouw werkbranch pushen. Om een patch die op GitHub staat lokaal te kunnen toepassen, moet je die eerst in je lokale checkout ophalen. De bridge commit, pusht, merge’t of publiceert niets en maakt geen PR.

## Problemen oplossen

- **Plugin staat niet in Studio:** controleer via **Plugins → Plugins Folder** dat je het bestand in de juiste map hebt gezet; controleer de extensie `.plugin.lua`; herstart Studio.
- **Verbinding geweigerd / timeout:** controleer dat `npm start` nog draait en dat de plugin-URL exact `http://127.0.0.1:47831` is.
- **HTTP 401 / tokenfout:** kopieer de token opnieuw uit de lopende terminal en druk op **Opslaan + testverbinding**.
- **HTTP 404 bij wijzigingen bekijken:** `studio/changes/latest.json` bestaat nog niet. Kopieer eerst het voorbeeldbestand of laat een patch maken.
- **Export niet zichtbaar op GitHub:** export schrijft eerst lokaal naar `studio/snapshots/latest.json`; gebruik daarna zelf Git om het bestand te committen en te pushen.
- **Studio weigert HTTP:** controleer de melding/toestemming van Studio. De plugin is bedoeld voor de lokale bridge op `127.0.0.1`, niet voor een publiek adres.
