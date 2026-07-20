# Signature et notarisation

CFPurge peut être distribué en signature ad hoc (développement) ou avec un certificat **Developer ID Application** (distribution publique Gatekeeper).

## Builds locaux / CI (ad hoc)

Par défaut, `project.yml` utilise :

```yaml
CODE_SIGN_IDENTITY: "-"
CODE_SIGN_STYLE: Manual
DEVELOPMENT_TEAM: ""
```

L'App Sandbox et les exceptions Application Support / Applications restent actives. L'access group Keychain est omis sans Team ID (voir `KeychainService`).

```bash
./build.sh test
./build.sh package universal v1.0.2
```

## Distribution Developer ID + notarisation

1. Obtenir un certificat **Developer ID Application** et une clé API Notary (App Store Connect)
2. Définir les secrets GitHub (déjà supportés par `.github/workflows/release.yml`) :
   - `APPLE_SIGNING_CERT_P12_BASE64`
   - `APPLE_SIGNING_CERT_PASSWORD`
   - `NOTARY_API_KEY_P8`
   - `NOTARY_KEY_ID`
   - `NOTARY_ISSUER_ID`
3. Pousser un tag `v*` — le workflow signe, notarise et stapple le `.dmg`

En local :

```bash
export CODE_SIGN_IDENTITY="Developer ID Application: …"
export NOTARY_API_KEY_P8=…
export NOTARY_KEY_ID=…
export NOTARY_ISSUER_ID=…
./build.sh package universal v1.0.2 --sign --notarize
```

Avec un Team ID, `KeychainService` active automatiquement l'access group `TEAMID.com.creactiveweb.cfpurge`.

## Gatekeeper

Sans notarisation, le premier lancement peut exiger **Clic droit → Ouvrir**. Avec notarisation, Gatekeeper accepte l'app normalement.
