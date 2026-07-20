import { getPreferenceValues, openExtensionPreferences } from "@raycast/api";

import { loadSites } from "./sites";
import { CFPurgeError, Site, SitesNotConfiguredError } from "./types";

export function getAPIToken(): string {
  const { apiToken } = getPreferenceValues<Preferences>();
  return apiToken?.trim() ?? "";
}

export function requireAPIToken(): string {
  const token = getAPIToken();
  if (!token) {
    void openExtensionPreferences();
    throw new CFPurgeError("Configurez votre token API Cloudflare dans les préférences de l'extension.");
  }
  return token;
}

export function requireSites(): Site[] {
  return loadSites();
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
