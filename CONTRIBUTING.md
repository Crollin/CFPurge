# Contribuer à CFPurge

Merci de votre intérêt pour CFPurge ! Ce guide couvre l'app macOS et l'extension Raycast.

## Prérequis

- macOS 14+
- [Xcode 15+](https://developer.apple.com/xcode/)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Node.js **22.22+** pour l'extension Raycast (`brew install node@22`)

## Démarrage rapide

```bash
git clone https://github.com/Crollin/CFPurge.git
cd CFPurge

# App macOS
xcodegen generate
open CFPurge.xcodeproj

# Extension Raycast
cd raycast-cfpurge
npm install
npm run dev
```

## Tests

```bash
# Tests unitaires Swift
xcodebuild -project CFPurge.xcodeproj -scheme CFPurge -destination 'platform=macOS' test

# Vérification TypeScript (extension Raycast)
cd raycast-cfpurge && npx tsc --noEmit

# Audit des dépendances npm (bloque high/critical)
cd raycast-cfpurge && npm audit --audit-level=high
```

La CI GitHub exécute aussi **gitleaks** (scan de secrets) sur chaque PR.

## Conventions

- **Langue UI** : français (messages utilisateur, labels)
- **Commits** : messages en français, impératif (« Ajouter… », « Corriger… »)
- **Swift** : suivre le style existant (enums pour les services, `@MainActor` sur les ViewModels)
- **TypeScript** : ESLint Raycast, pas de `any` sur les types API

## Structure

| Dossier | Rôle |
|---------|------|
| `CFPurge/` | App macOS SwiftUI (barre de menus) |
| `CFPurgeTests/` | Tests unitaires Swift |
| `raycast-cfpurge/` | Extension Raycast (TypeScript/React) |
| `project.yml` | Configuration xcodegen |

## Pull requests

1. Ouvrez une issue pour discuter des changements importants
2. Créez une branche depuis `main`
3. Assurez-vous que les tests passent
4. Mettez à jour le README si le comportement utilisateur change
5. Décrivez clairement le « pourquoi » dans la PR

## Sécurité

Ne commitez jamais de tokens API, Zone IDs réels ou données client. Voir [SECURITY.md](SECURITY.md).

Pour les builds de distribution (Developer ID / notarisation), voir [docs/SIGNING.md](docs/SIGNING.md).

## Licence

En contribuant, vous acceptez que vos contributions soient publiées sous la [licence MIT](LICENSE).
