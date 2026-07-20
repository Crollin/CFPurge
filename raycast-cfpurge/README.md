# CFPurge — Extension Raycast

Extension Raycast companion pour purger le cache Cloudflare depuis le lanceur, en réutilisant les sites configurés dans [CFPurge](../README.md).

La purge est **déléguée à l'app CFPurge** via le schéma d'URL `cfpurge://`. Aucun token API n'est stocké dans Raycast — le token reste uniquement dans le Keychain macOS.

## Prérequis

- [Raycast](https://raycast.com/) installé sur macOS
- Node.js **22.22+**
- **CFPurge** installé et configuré (token Keychain + au moins un site dans `~/Library/Application Support/CFPurge/sites.json`)

## Installation

### Mode développement

```bash
cd raycast-cfpurge
npm install
npm run dev
```

Raycast détecte automatiquement l'extension en mode développement. Les commandes apparaissent sous **CFPurge**.

### Installation permanente

```bash
npm run build
```

Puis dans Raycast : **Manage Extensions → + → Import Extension** et sélectionnez le dossier `raycast-cfpurge`.

> Pour publier sur le Raycast Store, utilisez `npm run publish` (nécessite un compte développeur Raycast).

## Configuration

1. Configurez CFPurge (token API + sites) — voir le [README principal](../README.md)
2. Aucune préférence token dans Raycast
3. Si vous aviez un ancien token dans les préférences Raycast : vous pouvez le supprimer, il n'est plus utilisé

## Commandes

| Commande | Description |
|----------|-------------|
| **Purger une URL** | Sélectionnez un site, saisissez une URL ou un chemin (`/blog/`), CFPurge exécute la purge |
| **Purger tout le cache** | Sélectionnez un site ; CFPurge demande confirmation avant la purge totale |

### Schéma d'URL

```
cfpurge://purge?siteId=<UUID>&url=<URL-encodée>
cfpurge://purge-all?siteId=<UUID>
```

### Exemples d'URL

| Saisie | URL envoyée |
|--------|-------------|
| `/contact/` | `https://monsite.com/contact/` |
| `contact` | `https://monsite.com/contact` |
| `https://monsite.com/page/` | `https://monsite.com/page/` |

## Dépannage

| Problème | Solution |
|----------|----------|
| « Configurez vos sites dans CFPurge d'abord » | Ouvrez CFPurge et ajoutez au moins un site |
| Rien ne se passe après la commande | Vérifiez que CFPurge.app est installé et que le schéma `cfpurge://` est enregistré |
| Token invalide | Configurez le token dans CFPurge → Réglages (plus dans Raycast) |
| Zone introuvable | Vérifiez le Zone ID dans CFPurge |
| Limite de requêtes | Attendez quelques minutes (rate limit Cloudflare) |

## Développement

```bash
npm run dev      # mode développement avec rechargement
npm run build    # compilation production
npx tsc --noEmit # vérification TypeScript
```

## Licence

MIT — voir [LICENSE](../LICENSE).
