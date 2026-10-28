import { Action, ActionPanel, Form, Icon, Toast, open, showToast } from "@raycast/api";
import { useState } from "react";

import { CFPURGE_BUNDLE_ID, buildPurgeURL } from "./lib/deep-link";
import { getErrorMessage } from "./lib/preferences";
import { SitesNotConfiguredDetail } from "./lib/sites-not-configured";
import { useSites } from "./lib/use-sites";
import { normalizeURL } from "./lib/url-normalizer";

interface FormValues {
  siteId: string;
  url: string;
}

export default function Command() {
  const [isLoading, setIsLoading] = useState(false);
  const { sites, errorMessage } = useSites();

  if (errorMessage) {
    return <SitesNotConfiguredDetail message={errorMessage} />;
  }

  async function handleSubmit(values: FormValues) {
    setIsLoading(true);

    try {
      const site = sites.find((entry) => entry.id === values.siteId);
      if (!site) {
        throw new Error("Site introuvable.");
      }

      const normalizedURL = normalizeURL(values.url, site);
      await open(buildPurgeURL(site.id, normalizedURL), CFPURGE_BUNDLE_ID);

      await showToast({
        style: Toast.Style.Success,
        title: "Purge déléguée à CFPurge",
        message: site.name,
      });
    } catch (error) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Échec de la purge",
        message: getErrorMessage(error),
      });
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Purger" icon={Icon.Trash} onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.Dropdown id="siteId" title="Site" storeValue>
        {sites
          .filter((site) => site.provider === "cloudflare")
          .map((site) => (
            <Form.Dropdown.Item
              key={site.id}
              value={site.id}
              title={`${site.name} (${site.domain})`}
              icon={Icon.Globe}
            />
          ))}
      </Form.Dropdown>
      <Form.TextField
        id="url"
        title="URL ou chemin"
        placeholder="/ma-page/ ou https://monsite.com/page/"
        autoFocus
      />
      <Form.Description text="Sites Cloudflare uniquement. Hostinger : utilisez « Purger tout ». La purge est exécutée par CFPurge." />
    </Form>
  );
}
