import { Action, ActionPanel, Detail } from "@raycast/api";

export function SitesNotConfiguredDetail({ message }: { message: string }) {
  return (
    <Detail
      markdown={`# Sites non configurés\n\n${message}\n\n1. Ouvrez **CFPurge** depuis la barre de menus\n2. Ajoutez au moins un site dans les réglages\n3. Relancez cette commande`}
      actions={
        <ActionPanel>
          <Action.OpenInBrowser title="Documentation CFPurge" url="https://github.com/Crollin/CFPurge" />
        </ActionPanel>
      }
    />
  );
}
