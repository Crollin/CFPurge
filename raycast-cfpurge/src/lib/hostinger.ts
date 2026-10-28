import { CFPurgeError } from "./types";

export async function purgeEverything(username: string, domain: string, token: string): Promise<void> {
  const encodedUsername = encodeURIComponent(username);
  const encodedDomain = encodeURIComponent(domain);
  const url = `https://developers.hostinger.com/api/hosting/v1/accounts/${encodedUsername}/websites/${encodedDomain}/cache/clear`;

  const response = await fetch(url, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
  });

  if (response.ok) {
    return;
  }

  let detail = `HTTP ${response.status}`;
  try {
    const body = (await response.json()) as { message?: string; error?: string };
    detail = body.message ?? body.error ?? detail;
  } catch {
    // ignore
  }

  if (response.status === 401) {
    throw new CFPurgeError("Jeton API Hostinger invalide ou expiré.");
  }
  throw new CFPurgeError(`Erreur API Hostinger : ${detail}`);
}
