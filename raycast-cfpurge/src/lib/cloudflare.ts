import { CFPurgeError } from "./types";

interface CloudflareAPIError {
  code: number;
  message: string;
}

interface CloudflarePurgeResponse {
  success: boolean;
  errors?: CloudflareAPIError[];
}

async function purgeCache(zoneId: string, token: string, body: Record<string, unknown>): Promise<void> {
  const response = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/purge_cache`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  let decoded: CloudflarePurgeResponse | undefined;
  try {
    decoded = (await response.json()) as CloudflarePurgeResponse;
  } catch {
    throw new CFPurgeError(`Réponse Cloudflare illisible (HTTP ${response.status}).`);
  }

  if (!response.ok || !decoded.success) {
    const message = decoded.errors?.[0]?.message ?? `HTTP ${response.status}`;
    if (response.status === 401) {
      throw new CFPurgeError("Jeton API Cloudflare invalide ou expiré.");
    }
    if (response.status === 429) {
      throw new CFPurgeError("Limite de requêtes Cloudflare atteinte. Réessayez plus tard.");
    }
    throw new CFPurgeError(`Erreur API Cloudflare : ${message}`);
  }
}

export async function purgeURLs(urls: string[], zoneId: string, token: string): Promise<void> {
  await purgeCache(zoneId, token, { files: urls });
}

export async function purgeEverything(zoneId: string, token: string): Promise<void> {
  await purgeCache(zoneId, token, { purge_everything: true });
}
