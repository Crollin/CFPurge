# CFPurge

Utilitaire macOS en barre de menus pour purger le cache Cloudflare de vos sites WordPress, sans ouvrir le dashboard Cloudflare.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![CI](https://github.com/Crollin/CFPurge/actions/workflows/ci.yml/badge.svg)

> Projet open source sous [licence MIT](LICENSE). Les contributions sont les bienvenues — voir [CONTRIBUTING.md](CONTRIBUTING.md).

## Fonctionnalités

- **Icône barre de menus** — app légère, sans icône dans le Dock
- **Multi-sites** — gérez tous vos sites WordPress Cloudflare depuis une liste
- **Purge par URL** — saisissez une URL complète ou un chemin (`/ma-page/`)
- **Purge totale** — vide tout le cache d'une zone (avec confirmation)
- **Jeton sécurisé** — stocké dans le Keychain macOS
- **Démarrage automatique** — option pour lancer CFPurge à la connexion
- **Gestion DNS** (optionnelle) — consultez et créez des enregistrements DNS Cloudflare
- **Interface en français**
- **Intégration Raycast** — purge depuis le lanceur via extension companion (voir [raycast-cfpurge/README.md](raycast-cfpurge/README.md))

## Prérequis

- macOS 14 (Sonoma) ou supérieur
- [Xcode 15+](https://developer.apple.com/xcode/) (pour compiler)
- Un [token API Cloudflare](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) avec la permission **Zone > Cache Purge** (Edit) sur vos zones
- Pour la gestion DNS (optionnelle) : ajoutez aussi **Zone > DNS** (Edit)

## Installation

### Téléchargement (recommandé)

1. Téléchargez le dernier `.dmg` depuis la page [Releases](https://github.com/Crollin/CFPurge/releases)
2. Ouvrez-le et glissez **CFPurge** dans **Applications**
3. Lancez l'app — les réglages s'ouvrent automatiquement au premier lancement

> **Premier lancement** : si l'app n'est pas notarisée, macOS peut la bloquer. Clic droit → **Ouvrir**, ou autorisez dans **Réglages Système → Confidentialité et sécurité**.

### Mises à jour

CFPurge vérifie automatiquement les nouvelles versions sur GitHub (toutes les 12 h). Depuis **Réglages → Général → Mises à jour**, vous pouvez :

- Vérifier manuellement
- Installer une mise à jour en un clic (l'app se ferme, remplace le bundle, puis relance)

### Installation rapide (développeurs)

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge
./install.sh
```

Le script compile en Release, copie l'app dans `/Applications` et la lance.

### Build from source

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge
xcodegen generate
open CFPurge.xcodeproj
```

Dans Xcode : **Product → Run** (⌘R), ou :

```bash
./build.sh test
./build.sh package universal v1.0.0
```

Le DMG est créé dans `dist/release/`.

### Publier une release

```bash
# 1. Mettre à jour MARKETING_VERSION dans project.yml
# 2. Ajouter une entrée dans CHANGELOG.md
# 3. Créer et pousser le tag
git tag v1.0.0
git push origin v1.0.0
```

Le workflow GitHub Actions compile, crée le `.dmg` et publie la release automatiquement.

## Configuration

1. Cliquez sur l'icône **nuage** dans la barre de menu
2. Au premier lancement, la fenêtre **Réglages** s'ouvre automatiquement
3. Collez votre **token API Cloudflare** → **Enregistrer** → **Tester la connexion**
4. **Ajoutez un site** :
   - **Nom** : libellé affiché dans l'app
   - **Zone ID** : visible dans Cloudflare → votre domaine → Aperçu (colonne droite)
   - **Domaine** : ex. `monsite.com` (sans `https://`)
5. Optionnel : activez **Lancer CFPurge à la connexion**
6. Optionnel : activez **Activer la gestion DNS** dans Réglages → Fonctionnalités

## Utilisation

| Action | Comment |
|---|---|
| Purger une page | Sélectionnez le site, saisissez l'URL ou le chemin, cliquez **Personnaliser le vidage** |
| Purger tout le cache | Sélectionnez le site, cliquez **Vider tous les éléments**, confirmez |
| Modifier les sites | Engrenage → section **Sites** |
| Gérer le DNS | Activez l'option DNS dans Réglages, puis **Gérer le DNS** (popover) ou **DNS** (par site) |

### Exemples d'URL

| Saisie | URL envoyée à Cloudflare |
|---|---|
| `/contact/` | `https://monsite.com/contact/` |
| `contact` | `https://monsite.com/contact` |
| `https://monsite.com/page/` | `https://monsite.com/page/` |

## Où sont stockées les données ?

| Donnée | Emplacement |
|---|---|
| Token API | Keychain macOS (`com.creactiveweb.cfpurge`) |
| Liste des sites | `~/Library/Application Support/CFPurge/sites.json` |
| Dernier site sélectionné | UserDefaults |

Le token n'est **jamais** écrit dans un fichier.

## API Cloudflare utilisée

```
GET  /client/v4/zones?per_page=1                    → vérification du token
POST /client/v4/zones/{zone_id}/purge_cache
     {"purge_everything": true}                    → purge totale
     {"files": ["https://..."]}                      → purge par URL
GET  /client/v4/zones/{zone_id}/dns_records         → liste des enregistrements DNS
POST /client/v4/zones/{zone_id}/dns_records         → création d'un enregistrement DNS
```

Documentation : [Purge cache — Cloudflare](https://developers.cloudflare.com/cache/how-to/purge-cache/) · [DNS records — Cloudflare](https://developers.cloudflare.com/dns/manage-dns-records/)

## Tests

```bash
xcodebuild -project CFPurge.xcodeproj -scheme CFPurge test
```

Tests unitaires : normalisation d'URL, validation de domaine, chemins relatifs.

## Intégration Raycast

Une extension Raycast companion permet de purger le cache directement depuis le lanceur, sans ouvrir CFPurge.

**Prérequis** : Node.js 22.22+ et [Raycast](https://raycast.com/).

```bash
cd raycast-cfpurge
npm install && npm run dev
```

Documentation complète : [raycast-cfpurge/README.md](raycast-cfpurge/README.md)

L'extension lit les sites depuis `~/Library/Application Support/CFPurge/sites.json` et utilise un token API configuré dans les préférences Raycast.

## Structure du projet

```
CFPurge/
├── CFPurge/
│   ├── Models/          # Site, réponses API, statuts
│   ├── Services/        # Keychain, SiteStore, Cloudflare API
│   ├── ViewModels/      # AppViewModel, DNSViewModel
│   ├── Views/           # MenuBar, Settings, SiteEditor, DNS
│   └── Utilities/       # URLNormalizer, erreurs
├── CFPurgeTests/
├── raycast-cfpurge/     # Extension Raycast companion
├── project.yml          # Config xcodegen
├── build.sh             # Build, tests et packaging DMG
├── CHANGELOG.md         # Notes de version (obligatoire pour les releases)
└── install.sh           # Script d'installation (dev)
```

## Dépannage

| Problème | Solution |
|---|---|
| L'icône nuage n'apparaît pas | Relancez l'app depuis `/Applications/CFPurge.app` |
| Les réglages ne s'ouvrent pas | Cliquez l'engrenage ou **Ouvrir les réglages** dans le popover |
| Token invalide | Vérifiez la permission **Cache Purge** sur toutes vos zones |
| Erreur DNS / 403 | Ajoutez la permission **Zone > DNS > Edit** à votre token API |
| Zone introuvable | Vérifiez le Zone ID dans le dashboard Cloudflare |
| Trop de purges | Cloudflare limite les purges totales, attendez quelques minutes |
| Démarrage auto ne fonctionne pas | L'app doit être dans `/Applications` |

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour les instructions de développement et de test.

## Sécurité

Pour signaler une vulnérabilité, consultez [SECURITY.md](SECURITY.md).

## Licence

MIT — voir [LICENSE](LICENSE).

## Auteur

[Développé par Creactive Web](https://github.com/Crollin)
