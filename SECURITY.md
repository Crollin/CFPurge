# Politique de sécurité

## Versions supportées

| Version | Supportée |
|---------|-----------|
| Dernière version sur `main` | ✅ |

Les versions antérieures ne reçoivent pas de correctifs de sécurité.

## Signaler une vulnérabilité

Si vous découvrez un problème de sécurité dans CFPurge ou l'extension Raycast, **ne pas** ouvrir d'issue publique.

Envoyez un rapport via [GitHub Security Advisories](https://github.com/Crollin/CFPurge/security/advisories/new) (recommandé) ou ouvrez une issue privée en contactant le mainteneur.

Incluez :

- Description du problème et impact potentiel
- Étapes pour reproduire
- Version de CFPurge / macOS concernée

Nous nous engageons à accuser réception sous **72 heures** et à proposer un correctif ou un plan d'action dans les **30 jours** pour les vulnérabilités confirmées.

## Bonnes pratiques pour les utilisateurs

- Créez un [token API Cloudflare](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) avec le **minimum de permissions** nécessaires :
  - **Zone > Cache Purge > Edit** pour la purge
  - **Zone > DNS > Edit** uniquement si vous utilisez la gestion DNS
- Limitez le token aux zones concernées, pas à tout le compte
- Ne partagez jamais votre token API ni le fichier `sites.json`
- Le token est stocké dans le **Keychain macOS** (app) ou les **préférences Raycast** (extension) — jamais dans le dépôt Git

## Données stockées localement

| Donnée | Emplacement | Sensibilité | Exposé à |
|--------|-------------|-------------|----------|
| Token API | Keychain macOS (`com.creactiveweb.cfpurge`) | **Élevée** | CFPurge uniquement |
| Token API (Raycast) | Préférences chiffrées Raycast | **Élevée** | Extension Raycast |
| Zone IDs, domaines | `~/Library/Application Support/CFPurge/sites.json` (permissions `600`) | **Moyenne** | Tout processus de l'utilisateur |
| Dossier CFPurge | `~/Library/Application Support/CFPurge/` (permissions `700`) | — | Utilisateur macOS uniquement |
| Dernier site sélectionné | UserDefaults | Faible | CFPurge |

Le token API **n'est jamais** écrit dans `sites.json` ni dans le dépôt Git.

## Risques utilisateur à connaître

- **Ne commitez pas** `sites.json` — il contient vos Zone IDs Cloudflare
- **Token minimal** : limitez les permissions et les zones du token API
- **Extension Raycast** : le token est stocké séparément du Keychain CFPurge (préférences Raycast)
- **Notifications macOS** : les URLs purgées peuvent apparaître dans le Centre de notifications
- **Gestion DNS** : si activée, un token compromis permet de modifier vos enregistrements DNS

## Périmètre

Ce projet interagit avec l'API Cloudflare en local. Les données sensibles (token API) restent sur votre machine et ne transitent que vers `api.cloudflare.com`.
