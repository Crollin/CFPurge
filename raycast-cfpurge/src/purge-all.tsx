import { Action, ActionPanel, Alert, Detail, Icon, List, Toast, confirmAlert, open, showToast } from "@raycast/api";
import { useState } from "react";

import { buildPurgeAllURL } from "./lib/deep-link";
import { getErrorMessage } from "./lib/preferences";
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
            <Action.OpenInBrowser title="Documentation CFPurge" url="https://github.com/Crollin/CFPurge" />
          </ActionPanel>
        }
      />
    );
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
      await open(buildPurgeAllURL(site.id));

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
