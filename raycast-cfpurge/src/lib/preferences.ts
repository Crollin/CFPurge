import { getPreferenceValues } from "@raycast/api";

import { CFPurgeError, SitesNotConfiguredError } from "./types";

export interface ExtensionPreferences {
  cloudflareToken: string;
  hostingerToken: string;
}

export function getPreferences(): ExtensionPreferences {
  return getPreferenceValues<ExtensionPreferences>();
}

export function requireCloudflareToken(): string {
  const token = getPreferences().cloudflareToken?.trim() ?? "";
  if (!token) {
    throw new CFPurgeError(
      "Configurez le jeton API Cloudflare dans les préférences de l'extension Raycast.",
    );
  }
  return token;
}

export function requireHostingerToken(): string {
  const token = getPreferences().hostingerToken?.trim() ?? "";
  if (!token) {
    throw new CFPurgeError(
      "Configurez le jeton API Hostinger dans les préférences de l'extension Raycast.",
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
