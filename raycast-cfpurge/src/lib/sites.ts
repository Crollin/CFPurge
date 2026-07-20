import { chmodSync, existsSync, readFileSync } from "fs";
import { homedir } from "os";
import { dirname, join } from "path";

import { isValidStoredSite } from "./site-validator";
import { Site, SitesNotConfiguredError } from "./types";

const sitesFilePath = join(homedir(), "Library", "Application Support", "CFPurge", "sites.json");

export function getSitesFilePath(): string {
  return sitesFilePath;
}

export function loadSites(): Site[] {
  if (!existsSync(sitesFilePath)) {
    throw new SitesNotConfiguredError();
  }

  enforcePermissions();

  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(sitesFilePath, "utf8"));
  } catch {
    throw new SitesNotConfiguredError();
  }

  if (!Array.isArray(raw) || raw.length === 0) {
    throw new SitesNotConfiguredError();
  }

  const sites = raw
    .map(parseSite)
    .filter((site): site is Site => site !== null)
    .filter((site) => isValidStoredSite(site.zoneId, site.domain));

  if (sites.length === 0) {
    throw new SitesNotConfiguredError();
  }

  return normalizeSortOrder(sites);
}

function enforcePermissions(): void {
  try {
    chmodSync(dirname(sitesFilePath), 0o700);
  } catch {
    // Best-effort
  }
  try {
    chmodSync(sitesFilePath, 0o600);
  } catch {
    // Best-effort
  }
}

function parseSite(value: unknown): Site | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const site = value as Record<string, unknown>;
  const id = String(site.id ?? "");
  const name = String(site.name ?? "");
  const zoneId = String(site.zoneId ?? "");
  const domain = String(site.domain ?? "");
  const sortOrder = typeof site.sortOrder === "number" ? site.sortOrder : 0;

  if (!id || !name || !zoneId || !domain) {
    return null;
  }

  return { id, name, zoneId, domain, sortOrder };
}

function normalizeSortOrder(sites: Site[]): Site[] {
  const sorted = [...sites].sort((a, b) => {
    if (a.sortOrder !== b.sortOrder) {
      return a.sortOrder - b.sortOrder;
    }
    return a.name.localeCompare(b.name, "fr", { sensitivity: "base" });
  });

  return sorted.map((site, index) => ({
    ...site,
    sortOrder: index,
  }));
}

export function findSiteById(sites: Site[], siteId: string): Site | undefined {
  return sites.find((site) => site.id === siteId);
}
