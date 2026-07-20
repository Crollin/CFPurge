# Contribuer à CFPurge

## Prérequis

- macOS 14+
- [Xcode 15+](https://developer.apple.com/xcode/)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Node.js **22.22+** pour l’extension Raycast

## Compiler / installer en local

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge
./install.sh          # Release → /Applications
# ou :
xcodegen generate && open CFPurge.xcodeproj
```

## Extension Raycast

```bash
cd raycast-cfpurge
npm install && npm run dev
```

## Vérifications avant PR

```bash
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

En contribuant, vous acceptez la [licence MIT](LICENSE).
