# Studio-bestandsformaten

Alle bestanden gebruiken JSON en `schemaVersion: 1`. De plugin en de bridge controleren de formaten vóór export/toepassing. Paden zijn arrays van segmenten; elk segment verwijst naar een child met dezelfde naam en klasse. `ordinal` is **1-based** onder children met diezelfde `name` én `className`, zodat namen die dubbel voorkomen toch aanspreekbaar zijn.

```json
[
  { "name": "Workspace", "className": "Workspace", "ordinal": 1 },
  { "name": "Props", "className": "Folder", "ordinal": 1 },
  { "name": "Tree", "className": "Model", "ordinal": 2 }
]
```

## Snapshot: `studio/snapshots/latest.json`

De plugin schrijft de laatst geëxporteerde selectie of Workspace naar dit bestand. Het bevat `exportedAt`, `placeName`, `roots` en per object `name`, `className`, `path`, `properties` en `children`. Als **Include script source** aanstaat, bevat Script/LocalScript/ModuleScript ook `source`.

Een part gebruikt bijvoorbeeld `Size`, `Position` en `Orientation` als `[x, y, z]`-arrays. `Color` is RGB met waarden tussen `0` en `1`; `Material` en `Shape` zijn Enum-namen. De snapshot is een beschrijving voor inspectie, geen volledige `.rbxl`-back-up.

## Wijzigingsbestand: `studio/changes/latest.json`

De plugin leest uitsluitend dit bestand. Een verandering krijgt een unieke `id`; gebruik een nieuwe id voor iedere nieuwe patch.

```json
{
  "schemaVersion": 1,
  "id": "obby-platform-v1",
  "summary": "Voeg een platform toe aan de start van de obby.",
  "operations": [
    {
      "op": "create",
      "parent": [
        { "name": "Workspace", "className": "Workspace", "ordinal": 1 }
      ],
      "node": {
        "name": "StartPlatform",
        "className": "Part",
        "properties": {
          "Anchored": true,
          "Size": [24, 1, 24],
          "Position": [0, 0, 0],
          "Color": [0.2, 0.6, 0.3],
          "Material": "Grass",
          "Shape": "Block"
        },
        "children": []
      }
    }
  ]
}
```

Ondersteunde operaties, in volgorde:

- `create`: maakt een object onder `parent`. `node` kan `children` bevatten, zodat een heel `Model` met Parts in één operatie gebouwd kan worden. Een nieuw BasePart is standaard verankerd; zet `Anchored: false` expliciet voor bewegende onderdelen.
- `set`: wijzig properties van het object op `path`.
- `setSource`: wijzig `source` van een bestaande Script, LocalScript of ModuleScript op `path`.
- `delete`: verwijder het object op `path` (services zoals Workspace zelf kunnen niet worden verwijderd).

Toegestane creatieklassen: `Model`, `Folder`, `Part`, `SpawnLocation`, `Script`, `LocalScript`, `ModuleScript`, `PointLight`, `SpotLight`, `Attachment`, `Decal` en `Texture`.

Toegestane propertynamen zijn class-afhankelijk. De plugin ondersteunt o.a.:

- BaseParts: `Anchored`, `CanCollide`, `CanTouch`, `CanQuery`, `CastShadow`, `Transparency`, `Reflectance`, `Size`, `Position`, `Orientation`, `Color`, `Material`.
- `Part`: ook `Shape` (`Block`, `Ball` of `Cylinder`).
- `SpawnLocation`: ook `Neutral` en `Duration`.
- Scripts: `Disabled`; broncode alleen via de aparte `setSource`-operatie.
- `PointLight`/`SpotLight`: `Enabled`, `Brightness`, `Range`, `Color`, `Shadows`; SpotLight ook `Angle` en `Face`.
- `Attachment`: `Position`, `Orientation`.
- `Decal`/`Texture`: `Texture`, `Transparency`, `Face`, `Color3`.

Vector3- en Color3-waarden zijn arrays van drie getallen. Colors liggen tussen 0 en 1. Enum-propertywaarden zijn strings, bijvoorbeeld `"Neon"`, `"Ball"` of `"Top"`. `Source` is geen property die via `set` kan worden gewijzigd.

De plugin toont eerst een preview en past de operaties daarna één voor één toe. Als een operatie tijdens het toepassen mislukt, kunnen eerdere operaties al zijn toegepast; Studio-undo-waypoints maken terugdraaien mogelijk.
