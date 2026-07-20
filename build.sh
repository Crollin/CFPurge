#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./build.sh [command] [arch] [version] [--sign] [--notarize]

Commands:
  test      Run unit tests
  build     Compile Release
  package   Build CFPurge.app and create a DMG
  release   Alias for: test + package

Arguments:
  arch      universal, arm64, or x86_64 (default: universal)
  version   Release version like v1.2.3
  --sign    Sign with a Developer ID Application certificate
  --notarize
            Submit and staple using Notary API secrets

Environment (notarization):
  NOTARY_API_KEY_P8   Base64-encoded App Store Connect API private key
  NOTARY_KEY_ID       App Store Connect API key ID
  NOTARY_ISSUER_ID    App Store Connect API issuer UUID

Examples:
  ./build.sh test
  ./build.sh package
  ./build.sh package universal v1.0.0
  ./build.sh package universal v1.0.0 --sign --notarize
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$script_dir"
derived_data="$repo_root/.build/DerivedData"
dist_dir="$repo_root/dist/release"
staging_root="${TMPDIR:-/tmp}/CFPurge-dmg"
code_sign_identity="${CODE_SIGN_IDENTITY:--}"
notary_work=""

cleanup() {
  if [[ -n "$notary_work" ]]; then
    rm -rf "$notary_work"
  fi
}
trap cleanup EXIT

ensure_xcode_project() {
  if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required (brew install xcodegen)" >&2
    exit 1
  fi
  xcodegen generate
}

build_release() {
  local arch="$1"
  local archs="$arch"

  if [[ "$arch" == "universal" ]]; then
    archs="arm64 x86_64"
  fi

  rm -rf "$derived_data"
  xcodebuild \
    -project "$repo_root/CFPurge.xcodeproj" \
    -scheme CFPurge \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="$archs" \
    CODE_SIGN_IDENTITY="$code_sign_identity" \
    CODE_SIGNING_ALLOWED=YES \
    -quiet \
    build
}

app_bundle_path() {
  find "$derived_data/Build/Products/Release" -name "CFPurge.app" -type d -print -quit
}

notarize_and_staple() {
  local target="$1"
  local submission="$target"

  if [[ "$target" == *.app ]]; then
    submission="$notary_work/$(basename "$target").zip"
    /usr/bin/ditto -c -k --keepParent "$target" "$submission"
  fi

  echo "Submitting $(basename "$target") to Apple for notarization..."
  xcrun notarytool submit "$submission" \
    --key "$notary_work/AuthKey.p8" \
    --key-id "$NOTARY_KEY_ID" \
    --issuer "$NOTARY_ISSUER_ID" \
    --wait
  xcrun stapler staple "$target"
  xcrun stapler validate "$target"
}

sign_app_if_requested() {
  local app_path="$1"
  if [[ "$sign_requested" != true ]]; then
    codesign --force --deep --sign - "$app_path" >/dev/null 2>&1 || true
    return
  fi

  xattr -cr "$app_path"
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --entitlements "$repo_root/CFPurge/CFPurge.entitlements" \
    --sign "$code_sign_identity" \
    "$app_path"
  codesign --verify --deep --strict --verbose=2 "$app_path"

  if [[ "$notarize_requested" == true ]]; then
    notarize_and_staple "$app_path"
  fi
}

command="${1:-release}"
if [[ $# -gt 0 ]]; then
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    test | build | package | release)
      command="$1"
      shift
      ;;
  esac
fi

sign_requested=false
notarize_requested=false
positional_args=()
for arg in "$@"; do
  case "$arg" in
    --sign)
      sign_requested=true
      ;;
    --notarize)
      notarize_requested=true
      ;;
    -*)
      echo "Unknown option: $arg" >&2
      usage
      exit 1
      ;;
    *)
      positional_args+=("$arg")
      ;;
  esac
done
if [[ ${#positional_args[@]} -gt 0 ]]; then
  set -- "${positional_args[@]}"
else
  set --
fi

if [[ $# -gt 2 ]]; then
  echo "Too many arguments" >&2
  usage
  exit 1
fi

arch="${1:-universal}"
version="${2:-}"

if [[ "$sign_requested" == true ]]; then
  if [[ "$command" != "package" && "$command" != "release" ]]; then
    echo "--sign is only supported with package or release" >&2
    exit 1
  fi
  if [[ "$code_sign_identity" == "-" ]]; then
    code_sign_identity="$(
      security find-identity -v -p codesigning |
        awk '/Developer ID Application:/ && !identity { identity = $2 } END { print identity }'
    )"
    if [[ -z "$code_sign_identity" ]]; then
      echo "No valid Developer ID Application identity was found in the keychain" >&2
      exit 1
    fi
  fi
fi

if [[ "$notarize_requested" == true ]]; then
  if [[ "$sign_requested" != true ]]; then
    echo "--notarize requires --sign" >&2
    exit 1
  fi
  if [[ -z "${NOTARY_API_KEY_P8:-}" || -z "${NOTARY_KEY_ID:-}" || -z "${NOTARY_ISSUER_ID:-}" ]]; then
    echo "Notarization requires NOTARY_API_KEY_P8, NOTARY_KEY_ID, and NOTARY_ISSUER_ID" >&2
    exit 1
  fi
  notary_work="$(mktemp -d "${TMPDIR:-/tmp}/CFPurge-notary.XXXXXX")"
  printf '%s' "$NOTARY_API_KEY_P8" | base64 --decode >"$notary_work/AuthKey.p8"
  chmod 600 "$notary_work/AuthKey.p8"
fi

case "$command" in
  test)
    ensure_xcode_project
    xcodebuild \
      -project "$repo_root/CFPurge.xcodeproj" \
      -scheme CFPurge \
      -destination 'platform=macOS' \
      -quiet \
      test
    ;;

  build)
    ensure_xcode_project
    build_release "$arch"
    ;;

  package | release)
    if [[ "$command" == "release" ]]; then
      ensure_xcode_project
      xcodebuild \
        -project "$repo_root/CFPurge.xcodeproj" \
        -scheme CFPurge \
        -destination 'platform=macOS' \
        -quiet \
        test
    fi

    if [[ -z "$version" ]]; then
      if git -C "$repo_root" describe --tags --exact-match >/dev/null 2>&1; then
        version="$(git -C "$repo_root" describe --tags --exact-match)"
      else
        version="v0.0.0-local"
      fi
    fi

    if [[ "$version" != v* ]]; then
      version="v$version"
    fi

    case "$arch" in
      universal)
        dmg_suffix=""
        ;;
      arm64)
        dmg_suffix="darwin-arm64"
        ;;
      x86_64)
        dmg_suffix="darwin-x86_64"
        ;;
      *)
        echo "Unsupported architecture: $arch" >&2
        exit 1
        ;;
    esac

    ensure_xcode_project
    build_release "$arch"

    app_path="$(app_bundle_path)"
    if [[ -z "$app_path" ]]; then
      echo "CFPurge.app not found after build" >&2
      exit 1
    fi

    if [[ "$arch" == "universal" ]]; then
      lipo "$app_path/Contents/MacOS/CFPurge" -verify_arch arm64 x86_64
    fi

    sign_app_if_requested "$app_path"

    mkdir -p "$dist_dir"
    # Empêche Spotlight/Launchpad d'indexer les artefacts locaux
    /usr/bin/touch "$repo_root/.build/.metadata_never_index" 2>/dev/null || true
    /usr/bin/touch "$repo_root/dist/.metadata_never_index" 2>/dev/null || true
    # Ne laisse pas un .app indexable par Launchpad/Spotlight dans le repo :
    # seul le .dmg est l'artefact de distribution.
    rm -rf "$dist_dir/CFPurge.app"

    rm -rf "$staging_root"
    mkdir -p "$staging_root"
    /usr/bin/ditto --noextattr --noqtn "$app_path" "$staging_root/CFPurge.app"
    # Empêche Spotlight d'indexer le staging temporaire
    /usr/bin/touch "$staging_root/.metadata_never_index" 2>/dev/null || true
    ln -sf /Applications "$staging_root/Applications"

    if [[ "$arch" == "universal" ]]; then
      dmg_path="$dist_dir/CFPurge-${version}.dmg"
    else
      dmg_path="$dist_dir/CFPurge-${version}-${dmg_suffix}.dmg"
    fi

    hdiutil create \
      -volname "CFPurge" \
      -srcfolder "$staging_root" \
      -ov \
      -format UDZO \
      "$dmg_path"

    if [[ "$sign_requested" == true ]]; then
      codesign --force --timestamp --sign "$code_sign_identity" "$dmg_path"
      codesign --verify --strict --verbose=2 "$dmg_path"
      if [[ "$notarize_requested" == true ]]; then
        notarize_and_staple "$dmg_path"
        codesign --verify --strict --verbose=2 "$dmg_path"
      fi
    fi

    echo "Created $dmg_path"
    rm -rf "$staging_root"
    ;;

  *)
    usage
    exit 1
    ;;
esac
