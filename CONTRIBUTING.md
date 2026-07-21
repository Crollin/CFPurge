# Contribuer à CFPurge

## Prérequis

- macOS 14+
- [Xcode 15+](https://developer.apple.com/xcode/)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Node.js **22.22+** pour l’extension Raycast

## Hooks Git (recommandé)

Une fois après le clone :

```bash
git config core.hooksPath .githooks
```

- **pre-commit** : refuse les fichiers inutiles / secrets / artefacts
- **pre-push** : un tag `v*` exige une entrée CHANGELOG + `MARKETING_VERSION` alignée

Vérification manuelle : `./scripts/check-repo-hygiene.sh`

## Garde-fous — ne pas committer

| Interdit | Exemples |
|----------|----------|
| Artefacts de build | `dist/`, `.build/`, `DerivedData/`, `*.app`, `*.dmg` |
| Dépendances | `node_modules/`, `Package.resolved` |
| Secrets | `.env`, `*.pem`, `*.p12`, `sites.json` |
| Scratch local | `.serena/`, `.superpowers/`, `.cursor/`, `docs/superpowers/` |
| Docs internes | tout sauf `docs/SIGNING.md` et `docs/BRAND.md` |
| Fichiers racine hors allowlist | seuls README, LICENSE, scripts, dossiers app, etc. |

La CI (job **Hygiène dépôt**) fait échouer la PR si un fichier interdit est tracké.

## Compiler / installer en local

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge
git config core.hooksPath .githooks
./install.sh          # écrase /Applications/CFPurge.app (config conservée)
./install.sh --raycast   # idem + déploie l'extension Raycast (Node 22.22+)
# Ne pas lancer les .app dans dist/ ou DerivedData (doublons Launchpad).
# ou :
xcodegen generate && open CFPurge.xcodeproj
```

## Extension Raycast

### Installation manuelle (première fois)

```bash
cd raycast-cfpurge
npm install && npm run build
```

Dans Raycast : **Manage Extensions → + → Import Extension** → dossier `raycast-cfpurge`.

### Mise à jour avec l'app (développeurs)

```bash
./install.sh --raycast
# ou seulement l'extension :
./scripts/install-raycast-extension.sh
```

Déploie vers `~/.config/raycast/extensions/cfpurge/` et recharge Raycast.

En développement : `cd raycast-cfpurge && npm run dev`.

## Vérifications avant PR

```bash
./scripts/check-repo-hygiene.sh
xcodebuild -project CFPurge.xcodeproj -scheme CFPurge -destination 'platform=macOS' test
cd raycast-cfpurge && npx tsc --noEmit && npm audit --audit-level=high
```

La CI exécute aussi gitleaks.

## Publier une release

1. Mettre à jour `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` dans `project.yml`
2. Ajouter une entrée `## [x.y.z]` dans `CHANGELOG.md`
3. Tag et push : `git tag v1.0.0 && git push origin v1.0.0`

Le workflow [Release](.github/workflows/release.yml) construit le `.dmg`. Signature / notarisation : [docs/SIGNING.md](docs/SIGNING.md).

## Conventions

- UI et messages utilisateur en **français**
- Commits en français, impératif
- Pas de tokens, Zone IDs réels ou données client dans le dépôt — voir [SECURITY.md](SECURITY.md)
- README public = présentation + installation uniquement ; le reste va dans CONTRIBUTING / docs autorisés

En contribuant, vous acceptez la [licence MIT](LICENSE).
