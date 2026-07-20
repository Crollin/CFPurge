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
- Limitez le token aux **zones concernées**, pas à tout le compte
- **Ne jamais** utiliser la Global API Key (refusée par l'app)
- Ne partagez jamais votre token API ni le fichier `sites.json`
- Le token est stocké **uniquement** dans le Keychain macOS (app). L'extension Raycast délègue via le schéma `cfpurge://` — aucun token dans les préférences Raycast
- Rotation : révoquez et recréez le token après compromission ou perte d'appareil

## Données stockées localement

| Donnée | Emplacement | Sensibilité | Exposé à |
|--------|-------------|-------------|----------|
| Token API | Keychain macOS (`com.creactiveweb.cfpurge`, access group dédié) | **Élevée** | CFPurge uniquement |
| Zone IDs, domaines | `~/Library/Application Support/CFPurge/sites.json` (permissions `600`) | **Moyenne** | Processus de l'utilisateur (lecture Raycast) |
| Dossier CFPurge | `~/Library/Application Support/CFPurge/` (permissions `700`) | — | Utilisateur macOS uniquement |
| Dernier site sélectionné | UserDefaults | Faible | CFPurge |

Le token API **n'est jamais** écrit dans `sites.json` ni dans le dépôt Git.

## Durcissement applicatif

- **App Sandbox** + accès réseau client uniquement
- Exception sandbox ciblée pour `~/Library/Application Support/CFPurge/` (partage sites avec Raycast)
- Keychain : `WhenUnlockedThisDeviceOnly`, non synchronisable iCloud, access group
- Validation stricte : Zone ID (32 hex), domaine, longueur minimale du token
- Notifications : URLs masquées par défaut
- CI : gitleaks + `npm audit --audit-level=high`

## Risques utilisateur à connaître

- **Ne commitez pas** `sites.json` — il contient vos Zone IDs Cloudflare
- **Token minimal** : limitez les permissions et les zones du token API
- **Extension Raycast** : nécessite CFPurge installé ; la purge passe par `cfpurge://` (pas de second token)
- **Notifications macOS** : activez « Afficher les URLs » uniquement si nécessaire
- **Gestion DNS** : si activée, un token compromis permet de modifier vos enregistrements DNS
- **Signature / notarisation** : pour une distribution hors GitHub Actions, utilisez un certificat Developer ID

## Périmètre

Ce projet interagit avec l'API Cloudflare en local. Les données sensibles (token API) restent sur votre machine et ne transitent que vers `api.cloudflare.com`.
