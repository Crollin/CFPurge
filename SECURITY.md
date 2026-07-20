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

## Périmètre

Ce projet interagit avec l'API Cloudflare en local. Les données sensibles (token API) restent sur votre machine et ne transitent que vers `api.cloudflare.com`.
