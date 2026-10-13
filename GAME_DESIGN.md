# Gameconcept — survival, boten en de glitch

Werknaam: nog niet gekozen. Dit document ordent de ideeën van de maker; details die nog open zijn, blijven open.

## Kerngevoel

Een spannende survival-avonturengame met een verhaal en een lichte tycoonlaag. De speler begint alsof die met een groep vrienden op vakantie is, maar moet gaandeweg ontdekken dat het eiland, de oceaan en de herinneringen niet kloppen. De basis en boot zijn uitbreidbaar; de focus blijft verkennen, overleven en het verhaal ontrafelen.

## Verhaal

- De speler ontwaakt op een onbekend eiland. Het huisje en de spullen geven de indruk dat de groep op vakantie is; het huisje wordt later de vaste basis.
- Rondom liggen kleine eilanden met loot. Op zee komen stormen voor die als een muur de bekende wereld omsluiten.
- Werknaam voor het mysterieuze oceaangebied: de **Berumida-driehoek**, een fictieve, speelse verwijzing naar de echte Bermudadriehoek en de verhalen over mysteries daar.
- Berichten en aanwijzingen die de groep tijdens de ontsnapping achterliet, brengen herinneringen terug.
- De waarheid: de speler en vrienden waren professoren die vreemde verschijnselen in de oceaan onderzochten. Na een doorbraak kwam een glitch in de wereld vrij. De groep ontsnapte, maar werd gehersenspoeld en weet niet meer wat er is gebeurd.
- Verderop zijn drie andere professoren te vinden. Ze waren ziek en hielden zich schuil toen ze merkten dat er iets mis was; zij onthullen een groot deel van het verleden.
- Naarmate de speler verder komt, trekt de stormgrens terug en worden nieuwe delen van de kaart bereikbaar.
- De boss fight is het einde van het verhaalhoofdstuk, niet het einde van de game. De glitch kan niet definitief worden verslagen, maar wel verzwakt; daarna speel je door in endless survival, zoals bij een game die na de campaign doorloopt.
- De boss fight geeft loot/een beloning. De grote, opvallende langetermijnbeloning is de nieuwe paarse meter: Memories bereikt eerst 100%, schuift/verkleint daarna en maakt plaats voor een tweede meter met `???`. Die meter is echt bedoeld als post-boss progression/reward, maar de precieze functie blijft voor spelers nog geheim.

## Gameplay-lus

1. Kies in de lobby eventueel een boot, pass of starter pack.
2. Vertrek vanaf je basis, vaar naar eilanden en verzamel bruikbare loot.
3. Houd rekening met tijd, water/adem en gevaren op zee en in de storm.
4. Keer terug om je huisje/basis en boot te verbeteren.
5. Vind aanwijzingen, herstel Memories en ontgrendel nieuwe delen van het verhaal.
6. Versla de boss niet definitief: verzwak de glitch en speel daarna door in endless survival.

Voortgang moet opgeslagen kunnen worden, zodat spelers later met hun ontgrendelde spullen, starter kit en boot verdergaan.

## Lobby, parties, opgeslagen werelden en sessies

- De lobby is een veilige haven/hub buiten de survival-sessie. Eerste sfeeridee: een mysterieus oceaan-onderzoeksstation met een kaart en hints naar de **Berumida-driehoek**.
- De lobby krijgt een centrale spawn, party-/vertrektafel, een paneel voor opgeslagen werelden, botenshowroom en gewone shop, VIP-boot/pass-presentatie, starter-kitkeuze en een veilig testwater voor boten en turrets. Een plek in een party starten of samen spelen kost geen Robux.
- Een nieuwe party bestaat uit maximaal **5 spelers**. De speler die de party start wordt de **Pro-owner** van de opgeslagen wereld en diens gekozen/ontgrendelde boot is de boot die de groep gebruikt; een gast neemt dus niet automatisch zijn eigen boot mee.
- Bij **Start expeditie** gaat de groep met `TeleportService` naar één **reserved server**: een gereserveerde sessie voor die groep, niet een betaald Roblox-privéserverabonnement. Later krijgt die wereld één random seed die voor alle spelers gelijk is.
- In de lobby staat ook **Join opgeslagen wereld**. De Pro-owner kan mensen uitnodigen; de toegangslijst mag meer dan 10 leden bevatten, maar er kunnen maximaal **10 spelers tegelijk** in dezelfde wereld zijn. Als de server vol is, moet het spel dat duidelijk aangeven.
- Uitgenodigde leden kunnen pas bij een opgeslagen wereld aansluiten nadat de eerste speler van de startparty een boot heeft bestuurd en de startsteiger heeft verlaten. Tot dat moment blijft de join-optie vergrendeld. De startparty zelf kan wel samen vertrekken.
- Elke opgeslagen wereld bewaart later de random seed en voortgang, zodat opnieuw joinen dezelfde eilanden en builds terugbrengt in plaats van een nieuwe wereld te rollen.
- Rollen: de **Pro-owner** is de oorspronkelijke eigenaar, kan mensen uitnodigen en vertrouwde spelers tot **Owner** promoveren. Owners kunnen gewone leden toegang afnemen; alleen de Pro-owner beheert de Owner-rollen en kan niet door een Owner worden buitengesloten. Of Owners ook nieuwe leden mogen uitnodigen, bepalen we nog.
- Om spawn-traps tegen te gaan, kan de Pro-owner door door andere spelers gebouwde onderdelen heen lopen, maar niet door terrein of de vaste wereld heen. Een bouwvrije zone bij spawn kan daar later als extra bescherming bij komen.
- De tycoonlaag blijft in eerste instantie beperkt tot upgrades voor de basis en de boot.

## Speldag en campagneduur

- Eerste testdoel: één volledige in-game dag/nachtcyclus duurt **3 minuten echte speeltijd**. De eerste prototypeverdeling is **2 minuten daglicht en 1 minuut nacht**. Beide waarden zijn instelbaar; we passen ze aan als dagtaken of nachten te gehaast voelen.
- Bij dat tempo duren 10 actieve in-game dagen ongeveer 30 minuten. Als het VIP-schild inderdaad na 10 in-game dagen ververst, vernieuwt het tijdens een actieve sessie dus ongeveer elk halfuur; de klok loopt niet door wanneer de wereld offline is. Dit is nog een voorstel om te bevestigen.
- De boss verslaan is het einde van het verhaalhoofdstuk, niet van het spel: daarna begint endless survival. De totale campagneduur bepalen we met doelen/voortgang en niet alleen met de dagklok; de 3-minutencyclus kunnen we tijdens tests bijstellen.

## Gamepass-concept: VIP-boot en starter kit

Een permanente Roblox Game Pass geeft toegang tot een speciale VIP-boot (niet met gewone in-game munten te koop) én de VIP-starter kit. De genoemde eigenschappen zijn het gewenste eerste ontwerp; exacte cijfers en balans testen we later.

**VIP-boot**

- Topsnelheid: **2× de snelste boot die normaal in de shop te koop is**.
- Een schild met vaste shield-HP vangt schade op voordat de boot/bemanning gewone schade krijgt. Voorlopig voorstel: het vernieuwt na elke **10 in-game dagen** (bij de huidige testklok ongeveer 30 minuten actieve speeltijd); nog te bevestigen.
- Twee gewone turrets die een speler kan bemannen; als niemand ze bedient, richt en schiet een eenvoudige bot alleen op vijanden.
- Een sterkere turret die alleen de bestuurder kan bedienen.
- Een werkende dansvloer die de avatar laat dansen.
- Langeafstands-sonar toont eilandmarkeringen buiten de gewone renderafstand en alleen de categorie, geen exacte loot: `???`, `Food`, `Materials`, `Money` of `Utility`. `???` blijft mysterieus en verraadt geen verhaalinhoud.

**VIP-starter kit**

- Bewegingssnelheid als doel: **30 studs per seconde** en een dubbele sprong. We moeten nog bepalen of 30 studs/s de normale snelheid of alleen sprint is.
- Een gewone bandage herstelt **50% van de maximale health**, zonder boven de normale health uit te komen.
- Een mutant bandage healt niet. Beide toepassingen duren **30 seconden**: op een neergehaalde teamgenoot gebruiken om die te reviven, óf op jezelf gebruiken om een eenmalige `Totem of Undying`-achtige bescherming te activeren die je bij één dodelijke klap redt. De exacte health na de revive, onderbrekingen en het verbruik moeten nog worden bepaald.
- De kit bevat later de overige items die jij nog kiest. We bepalen ook nog of hij eenmaal per nieuwe expeditie wordt uitgedeeld en hoe hij bij opslaan/herjoin werkt; hij mag niet opnieuw worden uitgedeeld bij iedere serverjoin.

**Balanspunt om te testen:** 2× bootsnelheid, schild, drie turrets, sonar, 30 studs/s, dubbele sprong en een extra leven samen maken VIP erg krachtig. We bewaren jouw concept, maar testen snelheid, sonar en overlevingsvoordeel vóór verkoop. De gewone route, het verhaal en samen een party starten blijven speelbaar zonder Robux. Dubbele sprong krijgt een eigen invoerregel zodat die niet botst met wall-walk/dak-klimmen. Andere passes kunnen later vooral cosmetisch zijn, zoals boot-skins, vlaggen, outfits en emotes.

## Besturing (eerste ontwerp, toetsenbord)

- `Q`: dash naar links.
- `E`: dash naar rechts.
- `Shift`: dash naar voren.
- `Ctrl`: toggle sprint.
- `C`: crouch.
- Crouch en daarna `Space`: toggle liggen/prone.
- Dubbele `Space` vlak bij een muur: maximaal 30 seconden wall-walk.
- Dubbele `Space` bij een plafond/dak: vasthouden aan of op het dak blijven, maximaal 30 seconden. De speler kan richten waar die daarna heen springt, bijvoorbeeld voor een jump attack of een sprong naar een muur. Op het dak zelf niet rennen.

Later zijn bediening voor mobiel/controller en toegankelijkheidsinstellingen nodig.

## Gevaren en speciale systemen

- Knockback kan de speler ragdollend door de lucht sturen. Een landingsmeter, landingsanimatie en verschil tussen landen op je voeten of hard neerkomen zijn gewenst.
- Fall damage alleen na een zeer hoge val; de drempel is nog niet gekozen, ongeveer 100–150 studs als startidee.
- Water/adem als survivalmechaniek.
- Een monster waakt bij/in de stormgrens. Als de speler ernaar kijkt, klinkt een storende piep. Na ongeveer 30 seconden volgen korte herinneringsflarden: geschreeuw, glitchgeluid en een wazig/glitchachtig beeld. Na ongeveer 50 seconden verdwijnt het monster voor circa twee minuten. De bedoeling is vooral spanning en angst, niet voortdurend spelers doden.
- Wie ver genoeg door de storm vaart, komt aan de andere kant van de kaart uit.
- Een kaart-GUI toont andere spelers, behalve spelers die in de storm zitten.
- Een altijd zichtbare tijd-GUI toont tijd en dag/nacht.
- Een Memories-balk toont voortgang in het verhaal.
- Een klein glitch-fragment is onderdeel van de speler en kan soms helpen. De chatkrachten moeten juist onverwacht en grappig zijn om toevallig te ontdekken; er komt geen expliciete tutorial die de geheime zinnen verklapt. Voorbeelden: `why is this so slow?` kan de boot 20% sneller maken en `help meeee` kan een schild voor vijf seconden plus 20% healing geven. Er komt wel een cooldown, maar het blijft een geheim/easter egg en geen gewone knop in het abilities-menu. De chattekst wordt alleen gebruikt om zo'n toegestane trigger te herkennen, niet om gesprekken op te slaan.

## Voorstel voor de eerste speelbare prototype

Begin klein; bouw nog niet meteen het hele verhaal of de boss fight:

1. Een lobby-greybox: veilige spawn, vertreksteiger, partyplek voor 5 spelers, paneel met opgeslagen werelden, boten-/VIP-presentatie en veilige teststeiger. Eerst alleen de zichtbare indeling; echte partyknoppen, wereldopslag, Robux-aankopen en teleport komen later.
2. Eén start-eiland met het latere basishuisje en een veilige kust.
3. Een simpele dag/nacht- en tijd-GUI.
4. Eén bestuurbare boot en één dichtbijgelegen loot-eiland.
5. Een eenvoudige terugkeer naar de basis met één zichtbare upgrade.
6. Een veilige stormgrens die de minimap-spelers verbergt en een eerste verhaalhint.
7. Opslaan/herladen van basisvoortgang zodra de kernlus werkt.

Daarna pas uitbreiden met random generatie en reserved servers, survivalmeters, de drie professoren, de storm-monster, speciale bewegingen, lobby-economie en de boss/endless-modus. Zo kunnen we eerst het uiterlijk en de flow van de lobby kiezen, en daarna de basis, boot en varen speelbaar maken voordat de complexere systemen worden toegevoegd.

## Nog niet vastgelegd

- Titel, doelgroep, invite-/join-UI en sessieduur. De afgesproken startparty is maximaal 5 en een opgeslagen wereld maximaal 10 spelers tegelijk.
- Hoe lobby-/party-UI en de vertrekflow er precies uitzien.
- Of de eerste verdeling van 2 minuten daglicht en 1 minuut nacht prettig speelt, en welke resources de basis-upgrades nodig hebben.
- Of het VIP-schild na 10 in-game dagen of 10 echte dagen ververst, hoeveel shield-HP het heeft en hoe de bot-turrets mikken.
- Of VIP-bewegingssnelheid van 30 studs/s altijd geldt of alleen bij sprint, en of 2× bootsnelheid goed in balans blijft; testen vóór verkoop.
- Hoe de mutant bandage-interacties worden onderbroken, hoeveel health een revive geeft, wanneer hij wordt verbruikt en hoe de VIP-starter kit bij nieuwe expedities/herjoin wordt uitgedeeld. Beide interacties duren voorlopig 30 seconden.
- Welke starter packs gratis/verdienbaar zijn en welke eventuele cosmetische passes later komen.
- Hoe de random world seed, opnieuw verbinden, Pro-owner/Owner-rechten en voortgang per party worden opgeslagen.
- Namen, uiterlijk en gedrag van het monster en de drie professoren.
- Hoe stormteleport, glitchespreuken en de tweede `???`-meter precies werken.
- De precieze val-schadedrempel, adem/waterregels en wall-walk balans.
