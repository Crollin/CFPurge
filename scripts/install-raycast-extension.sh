#!/usr/bin/env bash
# Compile et déploie l'extension Raycast locale (développeurs).
# Cible : ~/.config/raycast/extensions/cfpurge/
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ext_src="$repo_root/raycast-cfpurge"
raycast_ext_dir="${RAYCAST_EXT_DIR:-$HOME/.config/raycast/extensions/cfpurge}"
min_node="22.22.2"
reload_url="raycast://extensions/raycast/raycast/reload-extensions"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Compile raycast-cfpurge et copie le build dans :
  $raycast_ext_dir

Options:
  -h, --help     Affiche cette aide
  --no-reload    Ne pas demander le rechargement des extensions Raycast

Variable d'environnement :
  RAYCAST_EXT_DIR   Dossier de destination (défaut : ~/.config/raycast/extensions/cfpurge)
EOF
}

reload=true
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --no-reload) reload=false ;;
    *) echo "Option inconnue : $arg" >&2; usage >&2; exit 1 ;;
  esac
done

if ! command -v node >/dev/null 2>&1; then
  echo "✗ Node.js requis (>= $min_node). Installez-le ou omettez --raycast." >&2
  exit 1
fi

node_version="$(node -v | sed 's/^v//')"
if [[ "$(printf '%s\n' "$min_node" "$node_version" | sort -V | head -1)" != "$min_node" ]]; then
  echo "✗ Node.js >= $min_node requis (trouvé : $node_version)." >&2
  exit 1
fi

if [[ ! -f "$ext_src/package.json" ]]; then
  echo "✗ Dossier extension introuvable : $ext_src" >&2
  exit 1
fi

build_dir="$(mktemp -d "${TMPDIR:-/tmp}/cfpurge-raycast.XXXXXX")"
cleanup() {
  rm -rf "$build_dir"
}
trap cleanup EXIT

echo "→ Extension Raycast : npm ci..."
(cd "$ext_src" && npm ci --no-audit --no-fund)

echo "→ Extension Raycast : compilation..."
(cd "$ext_src" && npx ray build -e dist -o "$build_dir" -I)

echo "→ Extension Raycast : déploiement vers $raycast_ext_dir ..."
mkdir -p "$raycast_ext_dir"
ditto --noextattr --noqtn "$build_dir/" "$raycast_ext_dir/"

if [[ "$reload" == true ]] && { [[ -d /Applications/Raycast.app ]] || command -v raycast >/dev/null 2>&1; }; then
  echo "→ Rechargement des extensions Raycast..."
  open "$reload_url" 2>/dev/null || true
fi

echo ""
echo "✓ Extension Raycast installée dans :"
echo "  $raycast_ext_dir"
echo "  Si besoin : Raycast → Manage Extensions → activer CFPurge."
