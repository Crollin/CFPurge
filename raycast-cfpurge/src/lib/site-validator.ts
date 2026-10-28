import { CFPurgeError, CDNProvider, Site } from "./types";

const zoneIdPattern = /^[a-fA-F0-9]{32}$/;
const domainPattern = /^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/;
const hostingUsernamePattern = /^[A-Za-z0-9._-]{2,64}$/;

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
