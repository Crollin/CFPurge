# CFPurge — Extension Raycast

Extension Raycast privée pour purger le cache Cloudflare depuis le lanceur, en réutilisant les sites configurés dans [CFPurge](../README.md).

## Prérequis

- [Raycast](https://raycast.com/) installé sur macOS
- Node.js 18+
- CFPurge configuré avec au moins un site dans `~/Library/Application Support/CFPurge/sites.json`
- Un [token API Cloudflare](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) avec **Zone > Cache Purge > Edit**

## Installation (privée)

```bash
cd raycast-cfpurge
npm install
npm run dev
```

Raycast détecte automatiquement l'extension en mode développement. Les commandes apparaissent sous **CFPurge**.

Pour un usage permanent sans serveur de dev :

```bash
npm run build
```

Puis dans Raycast : **Manage Extensions → + → Import Extension** et sélectionnez le dossier `raycast-cfpurge`.

## Configuration

1. Ouvrez les préférences de l'extension **CFPurge** dans Raycast
2. Collez votre **token API Cloudflare** (le même que dans l'app CFPurge)
3. Assurez-vous que CFPurge contient au moins un site configuré

> Le token est stocké dans les préférences Raycast, pas dans le Keychain CFPurge. Les deux apps utilisent le même token Cloudflare mais le stockent séparément.

## Commandes

| Commande | Description |
|----------|-------------|
| **Purger une URL** | Sélectionnez un site, saisissez une URL ou un chemin (`/blog/`), lancez la purge |
| **Purger tout le cache** | Sélectionnez un site dans la liste, confirmez la purge totale |

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
| Token invalide | Vérifiez le token dans les préférences Raycast |
| Accès refusé | Permission **Cache Purge > Edit** requise sur le token |
| Zone introuvable | Vérifiez le Zone ID dans CFPurge |
| Limite de requêtes | Attendez quelques minutes (rate limit Cloudflare) |

## Développement

```bash
npm run dev      # mode développement avec rechargement
npm run lint     # vérification ESLint
npm run build    # compilation production
```

## Licence

MIT — voir [LICENSE](../LICENSE).
