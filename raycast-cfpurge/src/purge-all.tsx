import { Action, ActionPanel, Alert, Icon, List, Toast, confirmAlert, open, showToast } from "@raycast/api";
import { useState } from "react";

import { CFPURGE_BUNDLE_ID, buildPurgeAllURL } from "./lib/deep-link";
import { getErrorMessage } from "./lib/preferences";
import { SitesNotConfiguredDetail } from "./lib/sites-not-configured";
import { Site } from "./lib/types";
import { useSites } from "./lib/use-sites";

export default function Command() {
  const [isLoading, setIsLoading] = useState(false);
  const { sites, errorMessage } = useSites();

  if (errorMessage) {
    return <SitesNotConfiguredDetail message={errorMessage} />;
  }

  async function handlePurgeAll(site: Site) {
    const confirmed = await confirmAlert({
      title: "Purger tout le cache ?",
      message: `Site : ${site.name} (${site.domain})\n\nCFPurge confirmera à nouveau avant d'exécuter la purge totale.`,
      primaryAction: {
        title: "Continuer",
        style: Alert.ActionStyle.Destructive,
      },
    });

    if (!confirmed) {
      return;
    }

    setIsLoading(true);

    try {
      await open(buildPurgeAllURL(site.id), CFPURGE_BUNDLE_ID);

      await showToast({
        style: Toast.Style.Success,
        title: "Demande envoyée à CFPurge",
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
    <List isLoading={isLoading} searchBarPlaceholder="Rechercher un site...">
      {sites.map((site) => (
        <List.Item
          key={site.id}
          title={site.name}
          subtitle={`${site.domain} · ${site.provider === "hostinger" ? "Hostinger" : "Cloudflare"}`}
          icon={Icon.Globe}
          actions={
            <ActionPanel>
              <Action
                title="Purger tout le cache"
                icon={Icon.Trash}
                style={Action.Style.Destructive}
                onAction={() => handlePurgeAll(site)}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
