# CFPurge (Raycast)

Purge Cloudflare / Hostinger via API depuis Raycast. Sites lus dans `~/Library/Application Support/CFPurge/sites.json`.

## Installation

```bash
./scripts/install-raycast-extension.sh
```

Puis quittez Raycast (`⌘Q`) et relancez.

Si Raycast affiche **Missing executable**, relancez le script (ne pas importer le source brut sans build).

## Jetons API

Les préférences natives Raycast ne s’affichent pas correctement sur certaines installs **Development**.  
Les jetons passent donc par une **commande dédiée** (LocalStorage Raycast) :

1. Lancez **Configurer les jetons** (ou ⌘K depuis Purger une URL / Purger tout)
2. Collez le jeton Cloudflare (et Hostinger si besoin)
3. Enregistrer

Ensuite : **Purger une URL** / **Purger tout le cache**.

Ces jetons ≠ Keychain de l’app macOS CFPurge.

## Commandes

- **Configurer les jetons** — Cloudflare + Hostinger
- **Purger une URL** — Cloudflare, une entrée par ligne (max 30)
- **Purger tout le cache** — Cloudflare / Hostinger

## Notes

- L’app macOS reste utile pour DNS, réglages multi-sites et purge tags/préfixes/hosts.
