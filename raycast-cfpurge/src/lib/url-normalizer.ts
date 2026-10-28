import { CFPurgeError, Site } from "./types";

export const MAX_URLS_PER_REQUEST = 30;

export function siteDomain(site: Site): string {
  return site.domain
    .toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/\/+$/, "");
}

export function hostMatches(host: string, domain: string): boolean {
  return host === domain || host.endsWith(`.${domain}`);
}

export function normalizeURL(input: string, site: Site): string {
  const trimmed = input.trim();
  if (!trimmed) {
    throw new CFPurgeError("L'URL ne peut pas être vide.");
  }

  const domain = siteDomain(site);

  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    let host: string | undefined;
    try {
      host = new URL(trimmed).hostname.toLowerCase();
    } catch {
      throw new CFPurgeError("URL invalide.");
    }

    if (!host || !hostMatches(host, domain)) {
      throw new CFPurgeError("Le domaine de l'URL ne correspond pas au site sélectionné.");
    }

    return trimmed;
  }

  const path = trimmed.startsWith("/") ? trimmed : `/${trimmed}`;
  const normalized = `https://${domain}${path}`;

  try {
    new URL(normalized);
  } catch {
    throw new CFPurgeError("URL invalide.");
  }

  return normalized;
}

export function normalizeManyURLs(input: string, site: Site): string[] {
  const lines = input
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  if (lines.length === 0) {
    throw new CFPurgeError("Veuillez saisir une URL à purger.");
  }
  if (lines.length > MAX_URLS_PER_REQUEST) {
    throw new CFPurgeError(`Maximum ${MAX_URLS_PER_REQUEST} entrées par requête Cloudflare.`);
  }

  const seen = new Set<string>();
  const result: string[] = [];
  for (const line of lines) {
    const normalized = normalizeURL(line, site);
    if (!seen.has(normalized)) {
      seen.add(normalized);
      result.push(normalized);
    }
  }
  return result;
}
