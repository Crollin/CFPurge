#!/usr/bin/env bash
# Compile et déploie l'extension Raycast locale (développeurs).
# Cible : ~/.config/raycast/extensions/cfpurge/
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ext_src="$repo_root/raycast-cfpurge"
raycast_ext_dir="${RAYCAST_EXT_DIR:-$HOME/.config/raycast/extensions/cfpurge}"
min_node="22.22.2"
reload_url="raycast://extensions/raycast/raycast/reload-extensions"
required_commands=(configure-tokens purge-url purge-all)

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

has_command_artifact() {
  local root="$1"
  local cmd="$2"
  [[ -e "$root/${cmd}.js" || -e "$root/${cmd}" || -d "$root/${cmd}" ]] && return 0
  find "$root" -name "${cmd}.js" -print -quit | grep -q .
}

echo "→ Extension Raycast : npm ci..."
(cd "$ext_src" && npm ci --no-audit --no-fund)

echo "→ Extension Raycast : compilation..."
if ! (cd "$ext_src" && npx ray build -e dist -o "$build_dir" -I); then
  echo "✗ Échec de la compilation Raycast (ray build)." >&2
  echo "  Vérifiez Node >= $min_node et les erreurs TypeScript ci-dessus." >&2
  exit 1
fi

echo "→ Extension Raycast : vérification des exécutables..."
for cmd in "${required_commands[@]}"; do
  if ! has_command_artifact "$build_dir" "$cmd"; then
    echo "✗ Build invalide : exécutable manquant pour la commande « $cmd »." >&2
    echo "  Contenu du build :" >&2
    find "$build_dir" -maxdepth 3 -print >&2 || true
    echo "  Cause typique : dossier source importé dans Raycast sans « npm run build »." >&2
    echo "  Solution : relancer ce script." >&2
    exit 1
  fi
done

echo "→ Extension Raycast : déploiement vers $raycast_ext_dir ..."
rm -rf "$raycast_ext_dir"
mkdir -p "$raycast_ext_dir"
ditto --noextattr --noqtn "$build_dir/" "$raycast_ext_dir/"

for cmd in "${required_commands[@]}"; do
  if ! has_command_artifact "$raycast_ext_dir" "$cmd"; then
    echo "✗ Déploiement incomplet dans $raycast_ext_dir (Missing executable : $cmd)." >&2
    exit 1
  fi
done

if [[ "$reload" == true ]] && { [[ -d /Applications/Raycast.app ]] || command -v raycast >/dev/null 2>&1; }; then
  echo "→ Rechargement des extensions Raycast..."
  open "$reload_url" 2>/dev/null || true
fi

echo ""
echo "✓ Extension Raycast installée dans :"
echo "  $raycast_ext_dir"
echo "  Si besoin : Raycast → Manage Extensions → activer CFPurge."
