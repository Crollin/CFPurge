import { CFPurgeError, CDNProvider, Site } from "./types";

const zoneIdPattern = /^[a-fA-F0-9]{32}$/;
const domainPattern = /^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/;
const hostingUsernamePattern = /^[A-Za-z0-9._-]{2,64}$/;
const globalAPIKeyPattern = /^[a-fA-F0-9]{37}$/;

export const MINIMUM_TOKEN_LENGTH = 40;

export function normalizeDomain(input: string): string {
  return input
    .trim()
    .replace(/^https?:\/\//i, "")
    .replace(/\/+$/, "")
    .toLowerCase();
}

export function validateZoneId(input: string): string {
  const trimmed = input.trim().toLowerCase();
  if (!zoneIdPattern.test(trimmed)) {
    throw new CFPurgeError("Zone ID invalide. Attendu : 32 caractères hexadécimaux.");
  }
  return trimmed;
}

export function validateHostingUsername(input: string): string {
  const trimmed = input.trim();
  if (!hostingUsernamePattern.test(trimmed)) {
    throw new CFPurgeError("Nom d'utilisateur Hostinger invalide.");
  }
  return trimmed;
}

export function validateDomain(input: string): string {
  const normalized = normalizeDomain(input);
  if (!normalized || !domainPattern.test(normalized)) {
    throw new CFPurgeError("Domaine invalide. Utilisez un hostname du type monsite.com.");
  }
  return normalized;
}

export function validateAPIToken(input: string): string {
  const trimmed = input.trim();
  if (!trimmed) {
    throw new CFPurgeError("Configurez votre token API Cloudflare dans les préférences de l'extension.");
  }
  if (globalAPIKeyPattern.test(trimmed)) {
    throw new CFPurgeError("Les Global API Keys sont refusées. Créez un token API avec des permissions limitées.");
  }
  if (trimmed.length < MINIMUM_TOKEN_LENGTH) {
    throw new CFPurgeError("Le jeton API semble trop court. Collez un token API Cloudflare (pas la Global API Key).");
  }
  return trimmed;
}

export function isValidStoredSite(site: Pick<Site, "provider" | "zoneId" | "domain" | "hostingUsername">): boolean {
  try {
    validateDomain(site.domain);
    if (site.provider === "hostinger") {
      validateHostingUsername(site.hostingUsername ?? "");
      return true;
    }
    validateZoneId(site.zoneId);
    return true;
  } catch {
    return false;
  }
}

export function parseProvider(value: unknown): CDNProvider {
  return value === "hostinger" ? "hostinger" : "cloudflare";
}
