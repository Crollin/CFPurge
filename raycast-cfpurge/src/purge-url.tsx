import { Action, ActionPanel, Form, Icon, Toast, showToast } from "@raycast/api";
import { useState } from "react";

import { purgeURLs } from "./lib/cloudflare";
import { getErrorMessage } from "./lib/preferences";
import { SitesNotConfiguredDetail } from "./lib/sites-not-configured";
import { TokenSetupForm } from "./lib/token-setup-form";
import { requireCloudflareToken } from "./lib/tokens";
import { useSites } from "./lib/use-sites";
import { normalizeManyURLs } from "./lib/url-normalizer";

interface FormValues {
  siteId: string;
  urls: string;
}

export default function Command() {
  const [isLoading, setIsLoading] = useState(false);
  const [showTokenSetup, setShowTokenSetup] = useState(false);
  const { sites, errorMessage } = useSites();

  if (errorMessage) {
    return <SitesNotConfiguredDetail message={errorMessage} />;
  }

  if (showTokenSetup) {
    return <TokenSetupForm onDone={() => setShowTokenSetup(false)} />;
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

      const token = await requireCloudflareToken();
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
        primaryAction: message.includes("jeton")
          ? {
              title: "Configurer les jetons",
              onAction: () => setShowTokenSetup(true),
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
          <Action title="Configurer les jetons" icon={Icon.Key} onAction={() => setShowTokenSetup(true)} />
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
        info="Une entrée par ligne (max 30). Jetons : Action « Configurer les jetons » (⌘K)."
        autoFocus
      />
    </Form>
  );
}
