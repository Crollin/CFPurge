import {
  Action,
  ActionPanel,
  Alert,
  Icon,
  List,
  Toast,
  confirmAlert,
  openExtensionPreferences,
  showToast,
} from "@raycast/api";
import { useState } from "react";

import { purgeEverything as purgeCloudflareEverything } from "./lib/cloudflare";
import { purgeEverything as purgeHostingerEverything } from "./lib/hostinger";
import { getErrorMessage, requireCloudflareToken, requireHostingerToken } from "./lib/preferences";
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
      message: `Site : ${site.name} (${site.domain})\nFournisseur : ${site.provider === "hostinger" ? "Hostinger" : "Cloudflare"}`,
      primaryAction: {
        title: "Purger",
        style: Alert.ActionStyle.Destructive,
      },
    });

    if (!confirmed) {
      return;
    }

    setIsLoading(true);

    try {
      if (site.provider === "hostinger") {
        if (!site.hostingUsername) {
          throw new Error("Nom d'utilisateur Hostinger manquant pour ce site.");
        }
        const token = requireHostingerToken();
        await purgeHostingerEverything(site.hostingUsername, site.domain, token);
      } else {
        const token = requireCloudflareToken();
        await purgeCloudflareEverything(site.zoneId, token);
      }

      await showToast({
        style: Toast.Style.Success,
        title: "Cache vidé",
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
              <Action title="Ouvrir les préférences" icon={Icon.Gear} onAction={openExtensionPreferences} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
