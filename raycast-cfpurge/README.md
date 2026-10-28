# CFPurge (Raycast)

Purge le cache Cloudflare ou Hostinger **directement** depuis Raycast (appels API). Les sites viennent de `~/Library/Application Support/CFPurge/sites.json` (même fichier que l’app). Les jetons API se configurent dans les **préférences de l’extension** (indépendants du Keychain macOS de l’app).

## Installation

Depuis la racine du dépôt :

```bash
./scripts/install-raycast-extension.sh
```

Puis dans Raycast : **Extensions → CFPurge → Prefs** → coller les jetons Cloudflare / Hostinger.

Si Raycast affiche **Missing executable**, relancez le script (ne pas importer le source brut sans build).

## Commandes

- **Purger une URL** — Cloudflare ; une ou plusieurs URLs/chemins (une par ligne, max 30)
- **Purger tout le cache** — Cloudflare et Hostinger

## Notes

- Les jetons Raycast ≠ Keychain de l’app CFPurge : à configurer une fois dans chaque outil.
- L’app macOS reste utile pour DNS, réglages multi-sites et purge tags/préfixes/hosts.
