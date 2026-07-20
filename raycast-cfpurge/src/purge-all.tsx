import { Action, ActionPanel, Alert, Detail, Icon, List, Toast, confirmAlert, openExtensionPreferences, showToast } from "@raycast/api";
import { useMemo, useState } from "react";

import { purgeEverything } from "./lib/cloudflare";
import { getErrorMessage, requireAPIToken, requireSites } from "./lib/preferences";
import { Site, SitesNotConfiguredError } from "./lib/types";

export default function Command() {
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const sites = useMemo(() => {
    try {
      return requireSites();
    } catch (error) {
      if (error instanceof SitesNotConfiguredError) {
        setErrorMessage(error.message);
      } else {
        setErrorMessage(getErrorMessage(error));
      }
      return [];
    }
  }, []);

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
