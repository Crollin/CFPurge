# Changelog

Toutes les versions notables de CFPurge sont documentées ici.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [Unreleased]

### Ajouté

- `./install.sh --raycast` : option pour compiler et déployer l'extension Raycast locale (développeurs)
- Script `scripts/install-raycast-extension.sh` pour mettre à jour l'extension seule

### Documentation

- README : mention de `--raycast` pour les développeurs
- Positionnement générique : tout site derrière Cloudflare
- README recentré sur présentation + installation ; détails dev dans CONTRIBUTING
- Garde-fous dépôt : `.gitignore` renforcé, `scripts/check-repo-hygiene.sh`, hooks Git et job CI

## [1.0.4] — 2026-07-20

### Corrigé

- L’icône barre de menus réapparaît : `MenuBarExtra` utilise une `Image` rendue (plus un Canvas SwiftUI ignoré par le système)

## [1.0.3] — 2026-07-20

### Ajouté

- Nouvelle identité visuelle CFPurge : logo, favicon et icône Raycast
- Charte graphique documentée avec palette et règles d'utilisation

### Modifié

- Symbole CFPurge utilisé dans la barre de menus et le panneau de purge
- Couleurs des actions et états de purge harmonisées

### Corrigé

- Les mises à jour écrasent toujours `/Applications/CFPurge.app` (plus de doublons Launchpad)
- Le packaging ne laisse plus de `.app` indexable dans `dist/` ; `install.sh` remplace proprement l'ancienne version

## [1.0.2] — 2026-07-20

### Sécurité

- Validation stricte Zone ID (32 hex), domaine et token API (refus des Global API Keys)
- Notifications sans URL complète par défaut (option dans Réglages)
- Permissions `700`/`600` réappliquées à chaque lecture de `sites.json`
- App Sandbox + exceptions ciblées Application Support / Applications
- Keychain access group automatique lorsque l'app est signée avec un Team ID
- Extension Raycast : plus de token en préférences — délégation via `cfpurge://`
- CI : gitleaks + `npm audit --audit-level=high`

### Ajouté

- Schéma d'URL `cfpurge://purge` et `cfpurge://purge-all`
- Documentation signature / notarisation (`docs/SIGNING.md`)
- Guide token Cloudflare minimal dans le README

## [1.0.1] — 2026-07-20

### Ajouté

- Distribution via GitHub Releases (`.dmg` précompilé, build universel Apple Silicon + Intel)
- Vérification automatique des mises à jour via l'API GitHub Releases
- Installation in-app d'une nouvelle version depuis **Réglages → Général → Mises à jour**
- Script `build.sh` et workflow GitHub Actions `release.yml` pour publier automatiquement à chaque tag `v*`

## [1.0.0] — 2026-07-20

**CFPurge 1.0.0 — Purgez le cache Cloudflare depuis la barre de menus macOS**

CFPurge est un utilitaire macOS open source pour purger le cache Cloudflare de n'importe quel site derrière Cloudflare (CMS, site statique, application web, etc.). Il permet de vider le cache d'une page ou d'une zone entière en quelques clics, directement depuis la barre de menus — sans ouvrir le dashboard Cloudflare.

### Fonctionnalités

- **Barre de menus** — application légère, discrète, sans icône dans le Dock
- **Multi-sites** — gérez tous vos sites derrière Cloudflare depuis une liste unique
- **Purge par URL** — saisissez une URL complète ou un chemin relatif (`/contact/`, `blog/article`)
- **Purge totale** — videz tout le cache d'une zone Cloudflare (avec confirmation)
- **Sécurité** — token API Cloudflare stocké exclusivement dans le Keychain macOS
- **Gestion DNS** (optionnelle) — consultez et créez des enregistrements DNS Cloudflare
- **Démarrage automatique** — lancez CFPurge à la connexion macOS
- **Interface en français**
- **Extension Raycast** — purge depuis le lanceur via l'extension companion

### Prérequis

- macOS 14 (Sonoma) ou supérieur
- [Token API Cloudflare](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) avec la permission **Zone > Cache Purge > Edit**
- Pour la gestion DNS : ajoutez **Zone > DNS > Edit**

### Installation

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge
./install.sh
```

> Au premier lancement : clic droit sur **CFPurge.app** → **Ouvrir** si macOS bloque l'application (signature ad hoc).
