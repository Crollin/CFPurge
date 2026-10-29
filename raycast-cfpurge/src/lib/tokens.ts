import { LocalStorage } from "@raycast/api";

import { CFPurgeError } from "./types";

const CLOUDFLARE_KEY = "cloudflareToken";
const HOSTINGER_KEY = "hostingerToken";

export async function getCloudflareToken(): Promise<string | undefined> {
  const value = await LocalStorage.getItem<string>(CLOUDFLARE_KEY);
  const trimmed = value?.trim();
  return trimmed || undefined;
}

export async function getHostingerToken(): Promise<string | undefined> {
  const value = await LocalStorage.getItem<string>(HOSTINGER_KEY);
  const trimmed = value?.trim();
  return trimmed || undefined;
}

export async function setCloudflareToken(token: string): Promise<void> {
  const trimmed = token.trim();
  if (!trimmed) {
    await LocalStorage.removeItem(CLOUDFLARE_KEY);
    return;
  }
  await LocalStorage.setItem(CLOUDFLARE_KEY, trimmed);
}

export async function setHostingerToken(token: string): Promise<void> {
  const trimmed = token.trim();
  if (!trimmed) {
    await LocalStorage.removeItem(HOSTINGER_KEY);
    return;
  }
  await LocalStorage.setItem(HOSTINGER_KEY, trimmed);
}

export async function requireCloudflareToken(): Promise<string> {
  const token = await getCloudflareToken();
  if (!token) {
    throw new CFPurgeError('Aucun jeton Cloudflare. Lancez la commande « Configurer les jetons ».');
  }
  return token;
}

export async function requireHostingerToken(): Promise<string> {
  const token = await getHostingerToken();
  if (!token) {
    throw new CFPurgeError('Aucun jeton Hostinger. Lancez la commande « Configurer les jetons ».');
  }
  return token;
}
