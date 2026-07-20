# Changelog

Toutes les versions notables de CFPurge sont documentées ici.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [Unreleased]

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

CFPurge est un utilitaire macOS open source pensé pour les développeurs, intégrateurs et agences WordPress qui gèrent des sites derrière Cloudflare. Il permet de purger le cache d'une page ou d'un site entier en quelques clics, directement depuis la barre de menus — sans ouvrir le dashboard Cloudflare.

### Fonctionnalités

- **Barre de menus** — application légère, discrète, sans icône dans le Dock
- **Multi-sites** — gérez tous vos sites WordPress / Cloudflare depuis une liste unique
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
