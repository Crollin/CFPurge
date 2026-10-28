const SCHEME = "cfpurge";
export const CFPURGE_BUNDLE_ID = "com.creactiveweb.cfpurge";

export function buildPurgeURL(siteId: string, url: string): string {
  const params = new URLSearchParams({
    siteId,
    url,
  });
  return `${SCHEME}://purge?${params.toString()}`;
}

export function buildPurgeAllURL(siteId: string): string {
  const params = new URLSearchParams({ siteId });
  return `${SCHEME}://purge-all?${params.toString()}`;
}
