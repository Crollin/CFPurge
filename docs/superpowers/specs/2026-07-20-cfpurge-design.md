# CFPurge — Spécification

Application macOS 14+ (SwiftUI) en barre de menus pour purger le cache Cloudflare.

## Fonctionnalités

- Icône barre de menus uniquement (`LSUIElement`)
- Gestion multi-sites (nom, zone ID, domaine) persistée localement
- Jeton API Cloudflare stocké dans le trousseau
- Purge par URL/chemin ou purge totale
- Interface en français

## Architecture

- **Models** : `Site`, `PurgeStatus`, réponses API Cloudflare
- **Services** : Keychain, SiteStore, CloudflareService
- **ViewModel** : `AppViewModel` centralise l'état et les actions
- **Views** : `MenuBarView`, `SettingsView`, `SiteEditorView`

## API Cloudflare

- `GET /zones?per_page=1` — vérification du jeton
- `POST /zones/{zoneId}/purge_cache` — purge ciblée ou totale

## Bundle

- Identifiant : `com.creactiveweb.cfpurge`
