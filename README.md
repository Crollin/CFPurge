# CFPurge

Utilitaire macOS en barre de menus pour purger le cache Cloudflare de vos sites WordPress, sans ouvrir le dashboard Cloudflare.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Fonctionnalités

- **Icône barre de menus** — app légère, sans icône dans le Dock
- **Multi-sites** — gérez tous vos sites WordPress Cloudflare depuis une liste
- **Purge par URL** — saisissez une URL complète ou un chemin (`/ma-page/`)
- **Purge totale** — vide tout le cache d'une zone (avec confirmation)
- **Jeton sécurisé** — stocké dans le Keychain macOS
- **Démarrage automatique** — option pour lancer CFPurge à la connexion
- **Interface en français**

## Prérequis

- macOS 14 (Sonoma) ou supérieur
- [Xcode 15+](https://developer.apple.com/xcode/) (pour compiler)
- Un [token API Cloudflare](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) avec la permission **Zone > Cache Purge** (Edit) sur vos zones

## Installation rapide

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge
./install.sh
```

Le script compile en Release, copie l'app dans `/Applications` et la lance.

## Installation manuelle

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge
xcodegen generate
open CFPurge.xcodeproj
```

Dans Xcode : **Product → Run** (⌘R), ou :

```bash
xcodebuild -project CFPurge.xcodeproj -scheme CFPurge -configuration Release build
```

Copiez ensuite `CFPurge.app` depuis `DerivedData` vers `/Applications`.

> **Premier lancement** : macOS peut bloquer l'app (signature ad hoc). Clic droit → **Ouvrir**, ou autorisez dans **Réglages Système → Confidentialité et sécurité**.

## Configuration

1. Cliquez sur l'icône **nuage** dans la barre de menu
2. Au premier lancement, la fenêtre **Réglages** s'ouvre automatiquement
3. Collez votre **token API Cloudflare** → **Enregistrer** → **Tester la connexion**
4. **Ajoutez un site** :
   - **Nom** : libellé affiché dans l'app
   - **Zone ID** : visible dans Cloudflare → votre domaine → Aperçu (colonne droite)
   - **Domaine** : ex. `monsite.com` (sans `https://`)
5. Optionnel : activez **Lancer CFPurge à la connexion**

## Utilisation

| Action | Comment |
|---|---|
| Purger une page | Sélectionnez le site, saisissez l'URL ou le chemin, cliquez **Personnaliser le vidage** |
| Purger tout le cache | Sélectionnez le site, cliquez **Vider tous les éléments**, confirmez |
| Modifier les sites | Engrenage → section **Sites** |

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
GET  /client/v4/zones?per_page=1          → vérification du token
POST /client/v4/zones/{zone_id}/purge_cache
     {"purge_everything": true}            → purge totale
     {"files": ["https://..."]}            → purge par URL
```

Documentation : [Purge cache — Cloudflare](https://developers.cloudflare.com/cache/how-to/purge-cache/)

## Tests

```bash
xcodebuild -project CFPurge.xcodeproj -scheme CFPurge test
```

Tests unitaires : normalisation d'URL, validation de domaine, chemins relatifs.

## Structure du projet

```
CFPurge/
├── CFPurge/
│   ├── Models/          # Site, réponses API, statuts
│   ├── Services/        # Keychain, SiteStore, Cloudflare API
│   ├── ViewModels/      # AppViewModel
│   ├── Views/           # MenuBar, Settings, SiteEditor
│   └── Utilities/       # URLNormalizer, erreurs
├── CFPurgeTests/
├── project.yml          # Config xcodegen
└── install.sh           # Script d'installation
```

## Dépannage

| Problème | Solution |
|---|---|
| L'icône nuage n'apparaît pas | Relancez l'app depuis `/Applications/CFPurge.app` |
| Les réglages ne s'ouvrent pas | Cliquez l'engrenage ou **Ouvrir les réglages** dans le popover |
| Token invalide | Vérifiez la permission **Cache Purge** sur toutes vos zones |
| Zone introuvable | Vérifiez le Zone ID dans le dashboard Cloudflare |
| Trop de purges | Cloudflare limite les purges totales, attendez quelques minutes |
| Démarrage auto ne fonctionne pas | L'app doit être dans `/Applications` |

## Licence

MIT — voir [LICENSE](LICENSE).

## Auteur

[Développé par Creactive Web](https://github.com/Crollin)
