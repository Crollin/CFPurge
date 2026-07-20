# CFPurge — Extension Raycast

Purge le cache Cloudflare depuis Raycast en déléguant à l’app CFPurge (`cfpurge://`). Aucun token dans Raycast.

## Prérequis

- [Raycast](https://raycast.com/)
- CFPurge installé et configuré ([README](../README.md))
- Node.js 22.22+ (pour installer l’extension)

## Installation

```bash
cd raycast-cfpurge
npm install
npm run build
```

Dans Raycast : **Manage Extensions → + → Import Extension** → dossier `raycast-cfpurge`.

En développement : `npm run dev`.

## Utilisation

| Commande | Effet |
|----------|--------|
| **Purger une URL** | Ouvre CFPurge avec le site et l’URL |
| **Purger tout le cache** | Demande confirmation, puis CFPurge exécute |

Licence MIT — [LICENSE](../LICENSE).
