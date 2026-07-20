import { loadSites } from "./sites";
import { CFPurgeError, Site, SitesNotConfiguredError } from "./types";

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
