# Intégration Raycast — CFPurge

Extension Raycast privée pour purger le cache Cloudflare depuis le lanceur, en réutilisant la configuration sites de l'app CFPurge.

## Contexte

CFPurge est une app macOS barre de menus qui gère la purge cache Cloudflare pour tout site derrière Cloudflare. L'utilisateur souhaite déclencher une purge sans ouvrir l'app, directement depuis Raycast.

## Décision d'architecture

**Approche retenue : extension Raycast autonome**

- Lit `~/Library/Application Support/CFPurge/sites.json`
- Token API saisi dans les préférences Raycast (même token que CFPurge)
- Appelle directement l'API Cloudflare (`POST /zones/{zoneId}/purge_cache`)
- Aucune modification de l'app Swift requise

### Alternatives écartées

| Approche | Raison du rejet |
|----------|-----------------|
| URL scheme `cfpurge://` | Nécessite dev Swift + app en cours d'exécution |
| Lecture Keychain inter-app | Sandbox Raycast ≠ sandbox CFPurge, accès non fiable |
| CLI companion | Trop lourd pour le besoin initial |

## Commandes

### Purger une URL

- Formulaire : sélection site + saisie URL/chemin
- Normalisation identique à `URLNormalizer.swift`
- Toast succès/échec

### Purger tout le cache

- Liste des sites CFPurge
- Action destructive avec confirmation
- Purge totale via `{"purge_everything": true}`

## Données partagées

| Donnée | Source | Extension Raycast |
|--------|--------|-----------------|
| Sites (nom, zoneId, domaine) | `sites.json` | Lecture seule |
| Token API | Keychain CFPurge | Préférences Raycast (copie manuelle) |

## API Cloudflare

```
POST /client/v4/zones/{zone_id}/purge_cache
Authorization: Bearer {token}

# Purge URL
{"files": ["https://example.com/page"]}

# Purge totale
{"purge_everything": true}
```

Permission requise : **Zone > Cache Purge > Edit**

## Structure

```
raycast-cfpurge/
├── src/
│   ├── lib/
│   │   ├── types.ts
│   │   ├── sites.ts
│   │   ├── url-normalizer.ts
│   │   ├── cloudflare.ts
│   │   └── preferences.ts
│   ├── purge-url.tsx
│   └── purge-all.tsx
├── assets/icon.png
└── package.json
```

## Installation privée

```bash
cd raycast-cfpurge
npm install
npm run dev
```

Raycast détecte l'extension en mode développement. Pour un usage permanent : `npm run build` puis import via Manage Extensions.

## Évolutions futures (hors scope)

- URL scheme dans CFPurge pour notifications natives partagées
- Script Keychain avec prompt utilisateur
- Argument Raycast pour URL pré-remplie depuis le presse-papiers
