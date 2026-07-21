#!/bin/bash
set -euo pipefail

APP_NAME="CFPurge"
DEST="/Applications/${APP_NAME}.app"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
INSTALL_RAYCAST=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Compile CFPurge en Release et remplace /Applications/CFPurge.app.

Options:
  --raycast, --with-raycast
                 Compile et déploie aussi l'extension Raycast (développeurs)
  -h, --help     Affiche cette aide

Exemple :
  ./install.sh --raycast
EOF
}

for arg in "$@"; do
  case "$arg" in
    --raycast|--with-raycast) INSTALL_RAYCAST=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Option inconnue : $arg" >&2; usage >&2; exit 1 ;;
  esac
done

echo "→ Compilation Release..."
cd "$PROJECT_DIR"
xcodegen generate
xcodebuild -project CFPurge.xcodeproj -scheme CFPurge -configuration Release -quiet build

APP_PATH=$(find "$DERIVED_DATA" -path "*/Build/Products/Release/${APP_NAME}.app" -type d 2>/dev/null | head -1)

if [[ -z "$APP_PATH" ]]; then
  echo "Erreur : ${APP_NAME}.app introuvable après compilation."
  exit 1
fi

echo "→ Installation dans /Applications (remplacement de l'ancienne version)..."
# Supprime les doublons Finder éventuels (CFPurge 2.app, etc.)
find /Applications -maxdepth 1 -name "${APP_NAME} *.app" -exec rm -rf {} +
rm -rf "${DEST}.update-new" "${DEST}.update-old"
STAGE="${DEST}.install-new"
rm -rf "$STAGE"
ditto --noextattr --noqtn "$APP_PATH" "$STAGE"
xattr -cr "$STAGE" 2>/dev/null || true
rm -rf "$DEST"
mv "$STAGE" "$DEST"

# Empêche Spotlight/Launchpad d'indexer les copies de build locales
for dir in "$PROJECT_DIR/.build" "$PROJECT_DIR/dist"; do
  mkdir -p "$dir"
  touch "$dir/.metadata_never_index" 2>/dev/null || true
done
rm -rf "$PROJECT_DIR/dist/release/${APP_NAME}.app"

if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f "$DEST" >/dev/null 2>&1 || true
fi

if [[ "$INSTALL_RAYCAST" == true ]]; then
  echo ""
  bash "$PROJECT_DIR/scripts/install-raycast-extension.sh"
fi

echo "→ Lancement..."
open "$DEST"

echo ""
echo "✓ ${APP_NAME} installé dans /Applications"
echo "  Cliquez sur l'icône nuage dans la barre de menu."
echo "  Les réglages s'ouvrent automatiquement au premier lancement."
echo "  Config conservée : ~/Library/Application Support/CFPurge"
if [[ "$INSTALL_RAYCAST" == true ]]; then
  echo "  Extension Raycast mise à jour (option --raycast)."
fi
