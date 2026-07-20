import { Action, ActionPanel, Alert, Detail, Icon, List, Toast, confirmAlert, openExtensionPreferences, showToast } from "@raycast/api";
import { useState } from "react";

import { purgeEverything } from "./lib/cloudflare";
import { getErrorMessage, requireAPIToken } from "./lib/preferences";
import { Site } from "./lib/types";
import { useSites } from "./lib/use-sites";

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

  async function handlePurgeAll(site: Site) {
    const confirmed = await confirmAlert({
      title: "Purger tout le cache ?",
      message: `Site : ${site.name} (${site.domain})\n\nCette action vide tout le cache Cloudflare de la zone.`,
      primaryAction: {
        title: "Purger tout",
        style: Alert.ActionStyle.Destructive,
      },
    });

    if (!confirmed) {
      return;
    }

    setIsLoading(true);

    try {
      const token = requireAPIToken();
      await purgeEverything(site.zoneId, token);

      await showToast({
        style: Toast.Style.Success,
        title: "Cache entièrement purgé",
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
          subtitle={site.domain}
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
