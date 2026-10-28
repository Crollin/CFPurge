import { getPreferenceValues } from "@raycast/api";

import { CFPurgeError, SitesNotConfiguredError } from "./types";

/** Prefs héritées / déclarées par commande (voir package.json). */
export interface ExtensionPreferences {
  cloudflareToken?: string;
  hostingerToken?: string;
}

export function getPreferences(): ExtensionPreferences {
  return getPreferenceValues<ExtensionPreferences>();
}

export function requireCloudflareToken(): string {
  const token = getPreferences().cloudflareToken?.trim() ?? "";
  if (!token) {
    throw new CFPurgeError(
      "Configurez le jeton API Cloudflare : Réglages Raycast → Extensions → CFPurge → cliquez la commande « Purger une URL » (section Preferences).",
    );
  }
  return token;
}

export function requireHostingerToken(): string {
  const token = getPreferences().hostingerToken?.trim() ?? "";
  if (!token) {
    throw new CFPurgeError(
      "Configurez le jeton API Hostinger : Réglages Raycast → Extensions → CFPurge → cliquez « Purger tout le cache » (section Preferences).",
    );
  }
  return token;
}

export function getErrorMessage(error: unknown): string {
  if (error instanceof CFPurgeError || error instanceof SitesNotConfiguredError) {
    return error.message;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Une erreur inattendue est survenue.";
}
