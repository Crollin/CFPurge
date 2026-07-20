export interface Site {
  id: string;
  name: string;
  zoneId: string;
  domain: string;
  sortOrder: number;
}

export interface CloudflareAPIError {
  code: number;
  message: string;
}

export interface CloudflarePurgeResponse {
  success: boolean;
  errors?: CloudflareAPIError[];
  result?: {
    id?: string;
  };
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
