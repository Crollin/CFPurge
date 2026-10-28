export type CDNProvider = "cloudflare" | "hostinger";

export interface Site {
  id: string;
  name: string;
  zoneId: string;
  domain: string;
  sortOrder: number;
  provider: CDNProvider;
  hostingUsername?: string;
}

export class CFPurgeError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CFPurgeError";
  }
}

export class SitesNotConfiguredError extends CFPurgeError {
  constructor() {
    super("Configurez vos sites dans CFPurge d'abord.");
    this.name = "SitesNotConfiguredError";
  }
}
