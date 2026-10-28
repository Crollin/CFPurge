# CFPurge (Raycast)

Purge Cloudflare / Hostinger via API depuis Raycast. Sites lus dans `~/Library/Application Support/CFPurge/sites.json`.

## Installation

```bash
./scripts/install-raycast-extension.sh
```

Puis `⌘Q` Raycast et relance.

## Où mettre les jetons

Le menu `…` (View Build Folder / Uninstall) **ne contient pas** les jetons.

D’après la doc Raycast, les préférences s’affichent en **sélectionnant la commande** :

1. Raycast → **Settings** → **Extensions** → **CFPurge**
2. Clique sur la ligne **Purger une URL** (pas seulement le titre de l’extension)
3. Une section **Preferences** apparaît dessous → colle le **Jeton API Cloudflare**
4. Pour Hostinger : clique **Purger tout le cache** → champ Hostinger

Au premier lancement de la commande depuis le launcher, Raycast peut aussi demander les prefs `required`.

## Commandes

- **Purger une URL** — Cloudflare, une entrée par ligne (max 30)
- **Purger tout le cache** — Cloudflare / Hostinger

Les jetons Raycast ≠ Keychain de l’app CFPurge.
