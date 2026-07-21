# CFPurge

Utilitaire macOS en barre de menus pour purger le cache Cloudflare — page par page ou zone entière — sans ouvrir le dashboard.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Fonctionnalités

- Purge par URL ou chemin (`/ma-page/`)
- Purge totale d’une zone (avec confirmation)
- Multi-sites
- Token API dans le Keychain macOS
- Gestion DNS optionnelle
- Extension [Raycast](raycast-cfpurge/README.md) (délègue à l’app via `cfpurge://`)

## Installation

1. Téléchargez le `.dmg` sur la page [Releases](https://github.com/Crollin/CFPurge/releases)
2. Glissez **CFPurge** dans **Applications**
3. Lancez l’app — les réglages s’ouvrent au premier lancement

> Si macOS bloque l’app : clic droit → **Ouvrir**, ou autorisez dans **Réglages Système → Confidentialité et sécurité**.

Les mises à jour se vérifient automatiquement (Réglages → Général → Mises à jour).

## Configuration

1. Créez un [token API Cloudflare](https://dash.cloudflare.com/profile/api-tokens) avec **Zone → Cache Purge → Edit** (et **Zone → DNS → Edit** si vous activez le DNS). Limitez-le à vos zones. N’utilisez **jamais** la Global API Key.
2. Dans CFPurge → Réglages, collez le token → **Enregistrer** → **Tester la connexion**
3. Ajoutez un site : **nom**, **Zone ID** (32 caractères hex dans Cloudflare → domaine → Aperçu), **domaine** (`monsite.com`)

## Utilisation

| Action | Comment |
|--------|---------|
| Purger une page | Site → URL ou chemin → **Personnaliser le vidage** |
| Purger tout | Site → **Vider tous les éléments** → confirmer |
| Sites / DNS | Engrenage → Réglages |

## Licence

MIT — [LICENSE](LICENSE) · [Creactive Web](https://github.com/Crollin)

Pour contribuer ou compiler depuis les sources : [CONTRIBUTING.md](CONTRIBUTING.md) · signaler une vulnérabilité : [SECURITY.md](SECURITY.md)

**Développeurs** : `./install.sh` installe l’app en local ; ajoutez `--raycast` pour déployer aussi l’extension Raycast (`scripts/install-raycast-extension.sh`). Détails dans [CONTRIBUTING.md](CONTRIBUTING.md).
