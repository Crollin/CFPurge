import { Action, ActionPanel, Detail, Form, Icon, Toast, openExtensionPreferences, showToast } from "@raycast/api";
import { useState } from "react";

import { purgeURLs } from "./lib/cloudflare";
import { getErrorMessage, requireAPIToken } from "./lib/preferences";
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
    return (
      <Detail
        markdown={`# Sites non configurés\n\n${errorMessage}\n\n1. Ouvrez **CFPurge** depuis la barre de menus\n2. Ajoutez au moins un site dans les réglages\n3. Relancez cette commande`}
        actions={
          <ActionPanel>
            <Action title="Ouvrir les préférences Raycast" icon={Icon.Gear} onAction={openExtensionPreferences} />
          </ActionPanel>
        }
      />
    );
  }

  async function handleSubmit(values: FormValues) {
    setIsLoading(true);

    try {
      const token = requireAPIToken();
      const site = sites.find((entry) => entry.id === values.siteId);

      if (!site) {
        throw new Error("Site introuvable.");
      }

      const normalizedURL = normalizeURL(values.url, site);
      await purgeURLs([normalizedURL], site.zoneId, token);

      await showToast({
        style: Toast.Style.Success,
        title: "Cache purgé",
        message: normalizedURL,
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
        {sites.map((site) => (
          <Form.Dropdown.Item key={site.id} value={site.id} title={`${site.name} (${site.domain})`} icon={Icon.Globe} />
        ))}
      </Form.Dropdown>
      <Form.TextField
        id="url"
        title="URL ou chemin"
        placeholder="/ma-page/ ou https://monsite.com/page/"
        autoFocus
      />
    </Form>
  );
}
