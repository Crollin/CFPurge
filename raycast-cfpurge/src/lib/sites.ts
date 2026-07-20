import { homedir } from "os";
import { join } from "path";
import { readFileSync, existsSync } from "fs";

import { Site, SitesNotConfiguredError } from "./types";

const sitesFilePath = join(homedir(), "Library", "Application Support", "CFPurge", "sites.json");

export function getSitesFilePath(): string {
  return sitesFilePath;
}

export function loadSites(): Site[] {
  if (!existsSync(sitesFilePath)) {
    throw new SitesNotConfiguredError();
  }

  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(sitesFilePath, "utf8"));
  } catch {
    throw new SitesNotConfiguredError();
  }

  if (!Array.isArray(raw) || raw.length === 0) {
    throw new SitesNotConfiguredError();
  }

  const sites = raw.map(parseSite);
  return normalizeSortOrder(sites);
}

function parseSite(value: unknown): Site {
  if (!value || typeof value !== "object") {
    throw new SitesNotConfiguredError();
  }

  const site = value as Record<string, unknown>;
  const id = String(site.id ?? "");
  const name = String(site.name ?? "");
  const zoneId = String(site.zoneId ?? "");
  const domain = String(site.domain ?? "");
  const sortOrder = typeof site.sortOrder === "number" ? site.sortOrder : 0;

  if (!id || !name || !zoneId || !domain) {
    throw new SitesNotConfiguredError();
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
