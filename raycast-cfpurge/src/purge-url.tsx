import { Action, ActionPanel, Form, Icon, Toast, openExtensionPreferences, showToast } from "@raycast/api";
import { useState } from "react";

import { purgeURLs } from "./lib/cloudflare";
import { getErrorMessage, requireCloudflareToken } from "./lib/preferences";
import { SitesNotConfiguredDetail } from "./lib/sites-not-configured";
import { useSites } from "./lib/use-sites";
import { normalizeManyURLs } from "./lib/url-normalizer";

interface FormValues {
  siteId: string;
  urls: string;
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
      if (site.provider !== "cloudflare") {
        throw new Error("Purge par URL réservée aux sites Cloudflare.");
      }

      const token = requireCloudflareToken();
      const urls = normalizeManyURLs(values.urls, site);
      await purgeURLs(urls, site.zoneId, token);

      await showToast({
        style: Toast.Style.Success,
        title: urls.length === 1 ? "URL purgée" : `${urls.length} URLs purgées`,
        message: site.name,
      });
    } catch (error) {
      const message = getErrorMessage(error);
      await showToast({
        style: Toast.Style.Failure,
        title: "Échec de la purge",
        message,
        primaryAction:
          message.includes("préférences") || message.includes("jeton")
            ? {
                title: "Ouvrir les préférences",
                onAction: () => openExtensionPreferences(),
              }
            : undefined,
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
          <Action title="Ouvrir les préférences" icon={Icon.Gear} onAction={openExtensionPreferences} />
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
      <Form.TextArea
        id="urls"
        title="URL(s) ou chemins"
        placeholder={"/ma-page/\nhttps://monsite.com/autre/"}
        info="Une entrée par ligne (max 30). Le jeton Cloudflare est lu dans les préférences de l'extension."
        autoFocus
      />
    </Form>
  );
}
