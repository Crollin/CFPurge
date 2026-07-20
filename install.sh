#!/bin/bash
set -euo pipefail

APP_NAME="CFPurge"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

echo "→ Compilation Release..."
cd "$PROJECT_DIR"
xcodegen generate
xcodebuild -project CFPurge.xcodeproj -scheme CFPurge -configuration Release -quiet build

APP_PATH=$(find "$DERIVED_DATA" -path "*/Build/Products/Release/${APP_NAME}.app" -type d 2>/dev/null | head -1)

if [[ -z "$APP_PATH" ]]; then
  echo "Erreur : ${APP_NAME}.app introuvable après compilation."
  exit 1
fi

echo "→ Installation dans /Applications..."
rm -rf "/Applications/${APP_NAME}.app"
cp -R "$APP_PATH" "/Applications/${APP_NAME}.app"

echo "→ Lancement..."
open "/Applications/${APP_NAME}.app"

echo ""
echo "✓ ${APP_NAME} installé dans /Applications"
echo "  Cliquez sur l'icône nuage dans la barre de menu."
echo "  Les réglages s'ouvrent automatiquement au premier lancement."
