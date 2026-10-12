# Gameconcept — survival, boten en de glitch

Werknaam: nog niet gekozen. Dit document ordent de ideeën van de maker; details die nog open zijn, blijven open.

## Kerngevoel

Een spannende survival-avonturengame met een verhaal en een lichte tycoonlaag. De speler begint alsof die met een groep vrienden op vakantie is, maar moet gaandeweg ontdekken dat het eiland, de oceaan en de herinneringen niet kloppen. De basis en boot zijn uitbreidbaar; de focus blijft verkennen, overleven en het verhaal ontrafelen.

## Verhaal

- De speler ontwaakt op een onbekend eiland. Het huisje en de spullen geven de indruk dat de groep op vakantie is; het huisje wordt later de vaste basis.
- Rondom liggen kleine eilanden met loot. Op zee komen stormen voor die als een muur de bekende wereld omsluiten.
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

## Lobby en upgrades

- Boten om uit te kiezen.
- Robux-passes.
- Starter packs die niet met Robux gekocht hoeven te worden en waarmee de speler met gekozen startspullen kan beginnen.
- De tycoonlaag blijft in eerste instantie beperkt tot upgrades voor de basis en de boot.

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

1. Eén start-eiland met spawn, het latere basishuisje en een veilige kust.
2. Een simpele dag/nacht- en tijd-GUI.
3. Eén bestuurbare boot en één dichtbijgelegen loot-eiland.
4. Een eenvoudige terugkeer naar de basis met één zichtbare upgrade.
5. Een veilige stormgrens die de minimap-spelers verbergt en een eerste verhaalhint.
6. Opslaan/herladen van basisvoortgang zodra de kernlus werkt.

Daarna pas uitbreiden met survivalmeters, de drie professoren, de storm-monster, speciale bewegingen, lobby-economie en de boss/endless-modus. Zo kunnen de basis, boot en varen eerst speelbaar en leuk worden voordat de complexere systemen worden toegevoegd.

## Nog niet vastgelegd

- Titel, doelgroep, groepsgrootte en sessieduur.
- Hoe lang een dag/nacht duurt en welke resources de basis-upgrades nodig hebben.
- Namen, uiterlijk en gedrag van het monster en de drie professoren.
- Welke starter packs gratis/verdienbaar zijn en wat passes precies doen.
- Hoe stormteleport, glitchespreuken en de tweede `???`-meter precies werken.
- De precieze val-schadedrempel, adem/waterregels en wall-walk balans.
