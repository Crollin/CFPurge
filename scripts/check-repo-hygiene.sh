#!/usr/bin/env bash
# Garde-fou dépôt CFPurge : refuse les fichiers inutiles / dangereux dans Git.
# Utilisé par : .githooks/pre-commit et CI (job repo-hygiene).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failed=0

fail() {
  echo "✗ $*" >&2
  failed=1
}

ok() {
  echo "✓ $*"
}

# --- Patterns interdits s'ils sont trackés par Git ---
forbidden_regexes=(
  '(^|/)\.DS_Store$'
  '(^|/)node_modules/'
  '(^|/)(\.build|DerivedData|dist)/'
  '(^|/)xcuserdata/'
  '\.xcuserstate$'
  '(^|/)\.env(\.|$)'
  '(^|/)sites\.json$'
  '(^|/)\.serena/'
  '(^|/)\.superpowers/'
  '(^|/)docs/superpowers/'
  '(^|/)\.cursor/'
  '(^|/)\.claude/'
  '(^|/)\.codex/'
  '\.(dmg|ipa|pkg|p12|p8|pem|mobileprovision)$'
  '(^|/)Package\.resolved$'
  '(^|/)coverage/'
  '\.log$'
)

echo "==> Fichiers trackés interdits"
tracked="$(git ls-files -z | tr '\0' '\n')"
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  for re in "${forbidden_regexes[@]}"; do
    if [[ "$file" =~ $re ]]; then
      fail "fichier tracké interdit : $file (règle /$re/)"
    fi
  done
done <<< "$tracked"

# --- Allowlist racine du dépôt ---
echo "==> Contenu autorisé à la racine"
allowed_root=(
  .gitignore
  .gitattributes
  README.md
  LICENSE
  CHANGELOG.md
  CONTRIBUTING.md
  SECURITY.md
  project.yml
  build.sh
  install.sh
  CFPurge
  CFPurgeTests
  CFPurge.xcodeproj
  raycast-cfpurge
  docs
  scripts
  .github
  .githooks
)

shopt -s nullglob dotglob
for entry in * .[!.]* ..?*; do
  [[ "$entry" == "." || "$entry" == ".." || "$entry" == ".git" ]] && continue
  # ignorer ce que git ignore déjà (fichiers locaux)
  if git check-ignore -q "$entry" 2>/dev/null; then
    continue
  fi
  allowed=0
  for a in "${allowed_root[@]}"; do
    if [[ "$entry" == "$a" ]]; then
      allowed=1
      break
    fi
  done
  if [[ $allowed -eq 0 ]]; then
    # Si le fichier n'est pas tracké, ce n'est qu'un avertissement local
    if git ls-files --error-unmatch "$entry" >/dev/null 2>&1; then
      fail "entrée racine non autorisée (trackée) : $entry"
    else
      echo "⚠ entrée racine hors allowlist (non trackée, OK si gitignored) : $entry" >&2
    fi
  fi
done
shopt -u nullglob dotglob

# --- docs/ : pas de specs internes ---
echo "==> Contenu docs/"
if [[ -d docs ]]; then
  while IFS= read -r -d '' doc; do
    rel="${doc#./}"
    case "$rel" in
      docs/SIGNING.md|docs/BRAND.md) ;;
      docs/*)
        if git ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
          fail "doc non autorisée trackée : $rel (autorisés : docs/SIGNING.md, docs/BRAND.md)"
        fi
        ;;
    esac
  done < <(find docs -type f -print0 2>/dev/null)
fi

# --- Staging : refuse d'ajouter des junk si des fichiers sont staged ---
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "==> Fichiers staged (si applicable)"
  staged="$(git diff --cached --name-only --diff-filter=A 2>/dev/null || true)"
  if [[ -n "$staged" ]]; then
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      for re in "${forbidden_regexes[@]}"; do
        if [[ "$file" =~ $re ]]; then
          fail "ajout staged interdit : $file"
        fi
      done
      # Pas de nouveaux fichiers à la racine hors allowlist
      if [[ "$file" != */* ]]; then
        allowed=0
        for a in "${allowed_root[@]}"; do
          if [[ "$file" == "$a" ]]; then
            allowed=1
            break
          fi
        done
        if [[ $allowed -eq 0 ]]; then
          fail "nouveau fichier racine non autorisé : $file"
        fi
      fi
    done <<< "$staged"
  fi
fi

if [[ "$failed" -ne 0 ]]; then
  echo "" >&2
  echo "Hygiène dépôt : ÉCHEC. Retirez les fichiers ou mettez-les dans .gitignore." >&2
  echo "Voir CONTRIBUTING.md § Garde-fous." >&2
  exit 1
fi

ok "hygiène dépôt conforme"
exit 0
