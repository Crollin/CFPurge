# CFPurge (Raycast)

Purge le cache Cloudflare ou Hostinger depuis Raycast en déléguant à l’app CFPurge (`cfpurge://`). Aucun token dans Raycast.

## Installation

Depuis la racine du dépôt :

```bash
./scripts/install-raycast-extension.sh
```

Cela compile et déploie vers `~/.config/raycast/extensions/cfpurge/`.  
Si Raycast affiche **Missing executable**, le dossier déployé n’a pas d’artefacts compilés — relancez le script (ne pas importer le source brut sans `npm run build` / `npm run dev`).

## Commandes

- **Purger une URL** — sites Cloudflare uniquement
- **Purger tout le cache** — Cloudflare et Hostinger

Les sites sont lus depuis `~/Library/Application Support/CFPurge/sites.json` (même fichier que l’app). Les deep links ciblent le bundle `com.creactiveweb.cfpurge`.
