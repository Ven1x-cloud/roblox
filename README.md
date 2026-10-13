# Roblox Studio Git Bridge

Deze repo bevat een lokale Studio-plugin en bridge om een Roblox-place met de repo/AI te synchroniseren. **Het is nog niet de complete speelbare game**; je gamevisie staat in [GAME_DESIGN.md](GAME_DESIGN.md).

## Welk bestand gaat waar?

| Bestand/map | Wat doet het? | In Roblox zetten? |
|---|---|---|
| `plugin/RobloxGitBridge.plugin.lua` | De Studio-plugin. Kopieer alleen dit bestand naar **Plugins → Plugins Folder**. | **Ja, in de lokale Studio-pluginmap.** Niet in de Explorer/Workspace. |
| `bridge/` en `package.json` | De lokale HTTP-bridge; start hem met `npm start` buiten Studio. | Nee. Dit draait op je computer. |
| `studio/changes/latest.json` | Laatste patch van de assistent; de plugin haalt hem op. | Nee. De plugin voert de patch in de open place uit. |
| `studio/changes/latest.example.json` | Testpatch. Kopieer naar `latest.json` om de StarterObby te proberen. | Nee. |
| `studio/snapshots/latest.json` | Wereld- en scriptbeschrijving die de plugin automatisch exporteert. | Nee. Dit is geen `.rbxl`-place. |
| `studio/FORMAT.md` | Schema van snapshots en patches. | Nee. |
| `docs/ROBLOX_STUDIO_SETUP.md` | Installatie- en probleemoplossingsgids. | Nee. |

## Automatische synchronisatie

De plugin staat standaard met beide automatische functies **aan** (de instellingen worden in Studio onthouden):

- **Automatische wereldsync:** volgt wijzigingen in Workspace en belangrijke game-services zoals ReplicatedStorage, ServerScriptService, StarterGui en StarterPlayer. Na ongeveer drie seconden zonder wijziging stuurt hij een snapshot.
- **Automatisch GitHub-sync:** de bridge gebruikt je lokale Git-authenticatie om **alle gewijzigde repo-bestanden** met `git add -A` te committen en naar `arena/777e60cb-roblox` te pushen zodra er een nieuwe snapshot binnenkomt. Als de snapshot inhoudelijk niet veranderde en de repo verder schoon is, maakt Git geen lege commit.
- **AI-patches automatisch toepassen:** de plugin controleert iedere paar seconden op een nieuwe patch in de werkbranch en past die zonder preview toe. Dat omvat ook scriptbroncode en verwijderen, als de patch die operaties bevat.
- De bridge haalt GitHub-wijzigingen op met **fast-forward-only**. Bij een verkeerde branch, lokale wijzigingen die een update blokkeren of uiteenlopende branches stopt hij en meldt hij de fout. Hij force-pusht niet.

Je kunt in het pluginvenster **Automatische wereldsync** en **AI-patches automatisch toepassen** uitzetten. De server pusht alleen als `STUDIO_AUTO_GIT` aanstaat (standaard aan); zet `STUDIO_AUTO_GIT=0` vóór `npm start` om automatisch commit/push uit te schakelen. Omdat auto-sync de hele repo commit, laat je geen wachtwoorden, tokens of andere geheimen in niet-genegeerde bestanden staan. `.gitignore` sluit gebruikelijke lokale secret- en buildbestanden uit.

> Automatisch toepassen betekent dat een nieuwe patch zonder jouw preview de place wijzigt. `setSource` voert geen code uit met `loadstring`, maar een gewijzigd Script kan wel draaien zodra je de game start. Maak een place-kopie voordat je dit gebruikt. Schakel auto-apply uit als je patches eerst wilt bekijken. Studio-undo-waypoints worden gemaakt, maar een back-up is veiliger.

## Snel starten

1. Installeer Node.js 18 of hoger.
2. Kopieer `plugin/RobloxGitBridge.plugin.lua` naar de map die Studio opent met **Plugins → Plugins Folder**; herstart Studio.
3. Open een terminal in de repo-hoofdmap (waar `package.json` staat) en voer `npm start` uit. Laat de terminal open.
4. Plak de getoonde tijdelijke token in de plugin. De URL blijft `http://127.0.0.1:47831`. Klik **Opslaan + testverbinding**.
5. Open je place in Studio. Bij een wijziging wordt de snapshot automatisch bijgewerkt en, als Git-auto-sync aanstaat, naar de werkbranch gepusht. Je place zelf moet je nog steeds opslaan/publiceren in Studio.

De complete uitleg, inclusief de test-obby en foutmeldingen, staat in [docs/ROBLOX_STUDIO_SETUP.md](docs/ROBLOX_STUDIO_SETUP.md).

## GitHub- en PR-regel

De plugin bevat geen GitHub-token: de lokale bridge gebruikt Git dat al op je computer is ingesteld. Auto-push is beperkt tot `arena/777e60cb-roblox`. Er wordt **nooit automatisch een PR aangemaakt, gemerged of gesloten**. De lokale fast-forward haalt alleen nieuwe commits van diezelfde branch op; het is geen PR-merge. Bij een conflict of afwijkende branch stopt de bridge in plaats van te gokken.

## Ontwikkelen en testen

```sh
npm test
```

Configuratie:

- `STUDIO_BRIDGE_PORT` — standaard `47831`.
- `STUDIO_BRIDGE_TOKEN` — optioneel eigen token van minimaal 24 tekens; anders wordt er bij het starten een tijdelijke token gemaakt.
- `STUDIO_GIT_DIR` — optioneel pad naar de lokale repo als je de bridge ergens anders start.
- `STUDIO_AUTO_GIT=0` — schakel automatisch ophalen/committen/pushen uit.
