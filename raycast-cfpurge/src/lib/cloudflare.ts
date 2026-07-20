import { CFPurgeError, CloudflarePurgeResponse } from "./types";

const baseURL = "https://api.cloudflare.com/client/v4";

export async function purgeURLs(urls: string[], zoneId: string, token: string): Promise<void> {
  await purgeRequest(zoneId, token, { files: urls });
}

export async function purgeEverything(zoneId: string, token: string): Promise<void> {
  await purgeRequest(zoneId, token, { purge_everything: true });
}

async function purgeRequest(zoneId: string, token: string, body: Record<string, unknown>): Promise<void> {
  const response = await fetch(`${baseURL}/zones/${zoneId}/purge_cache`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const data = (await response.json()) as CloudflarePurgeResponse;

  if (response.status === 401) {
    throw new CFPurgeError("Token API invalide ou expiré.");
  }

  if (response.status === 403) {
    throw new CFPurgeError("Accès refusé. Vérifiez les permissions Cache Purge du token.");
  }

  if (response.status === 404) {
    throw new CFPurgeError("Zone Cloudflare introuvable.");
  }

  if (response.status === 429) {
    throw new CFPurgeError("Limite de requêtes atteinte. Réessayez dans quelques minutes.");
  }

  if (!response.ok) {
    throw mapAPIErrors(data.errors) ?? new CFPurgeError(`Erreur HTTP ${response.status}.`);
  }

  if (!data.success) {
    throw mapAPIErrors(data.errors) ?? new CFPurgeError("Erreur inconnue de l'API Cloudflare.");
  }
}

function mapAPIErrors(errors?: { code: number; message: string }[]): CFPurgeError | undefined {
  if (!errors?.length) {
    return undefined;
  }

  const first = errors[0];
  const message = first.message.toLowerCase();

  if (first.code === 1008 || message.includes("rate") || message.includes("limit")) {
    return new CFPurgeError("Limite de requêtes atteinte. Réessayez dans quelques minutes.");
  }

  return new CFPurgeError(first.message);
}
