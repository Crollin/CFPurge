import { CFPurgeError, Site } from "./types";

export function normalizeURL(input: string, site: Site): string {
  const trimmed = input.trim();
  if (!trimmed) {
    throw new CFPurgeError("L'URL ne peut pas être vide.");
  }

  const siteDomain = site.domain
    .toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/\/+$/, "");

  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    let host: string | undefined;
    try {
      host = new URL(trimmed).hostname.toLowerCase();
    } catch {
      throw new CFPurgeError("URL invalide.");
    }

    if (!host || !hostMatches(host, siteDomain)) {
      throw new CFPurgeError("Le domaine de l'URL ne correspond pas au site sélectionné.");
    }

    return trimmed;
  }

  const path = trimmed.startsWith("/") ? trimmed : `/${trimmed}`;
  const normalized = `https://${siteDomain}${path}`;

  try {
    new URL(normalized);
  } catch {
    throw new CFPurgeError("URL invalide.");
  }

  return normalized;
}

function hostMatches(host: string, siteDomain: string): boolean {
  return host === siteDomain || host.endsWith(`.${siteDomain}`);
}
