# CFPurge — Spécification

Application macOS 14+ (SwiftUI) en barre de menus pour purger le cache Cloudflare.

## Fonctionnalités

- Icône barre de menus uniquement (`LSUIElement`)
- Gestion multi-sites (nom, zone ID, domaine) persistée localement
- Jeton API Cloudflare stocké dans le trousseau
- Purge par URL/chemin ou purge totale
- Gestion DNS optionnelle (consultation + création d'enregistrements A, AAAA, CNAME, MX, TXT)
- Interface en français

## Architecture

- **Models** : `Site`, `PurgeStatus`, `DNSRecord`, réponses API Cloudflare
- **Services** : Keychain, SiteStore, CloudflareService
- **ViewModel** : `AppViewModel` centralise l'état purge ; `DNSViewModel` pour la gestion DNS
- **Views** : `MenuBarView`, `SettingsView`, `SiteEditorView`, `DNSRecordsView`, `DNSRecordEditorView`

## API Cloudflare

- `GET /zones?per_page=1` — vérification du jeton
- `POST /zones/{zoneId}/purge_cache` — purge ciblée ou totale
- `GET /zones/{zoneId}/dns_records` — liste des enregistrements DNS
- `POST /zones/{zoneId}/dns_records` — création d'un enregistrement DNS

## Permissions token

- Purge : **Zone > Cache Purge > Edit**
- DNS (optionnel) : **Zone > DNS > Edit**

## Bundle

- Identifiant : `com.creactiveweb.cfpurge`
