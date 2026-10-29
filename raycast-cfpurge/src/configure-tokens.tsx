import { Action, ActionPanel, Form, Icon, Toast, popToRoot, showToast } from "@raycast/api";
import { useEffect, useState } from "react";

import { getErrorMessage } from "./lib/preferences";
import {
  getCloudflareToken,
  getHostingerToken,
  setCloudflareToken,
  setHostingerToken,
} from "./lib/tokens";

interface FormValues {
  cloudflareToken: string;
  hostingerToken: string;
}

export default function Command() {
  const [isLoading, setIsLoading] = useState(true);
  const [cloudflareToken, setCf] = useState("");
  const [hostingerToken, setHi] = useState("");

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [cf, hi] = await Promise.all([getCloudflareToken(), getHostingerToken()]);
        if (!cancelled) {
          setCf(cf ?? "");
          setHi(hi ?? "");
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  async function handleSubmit(values: FormValues) {
    try {
      await setCloudflareToken(values.cloudflareToken);
      await setHostingerToken(values.hostingerToken);
      await showToast({
        style: Toast.Style.Success,
        title: "Jetons enregistrés",
        message: "Stockés dans Raycast (LocalStorage), pas dans le Keychain de l'app.",
      });
      await popToRoot();
    } catch (error) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Échec de l'enregistrement",
        message: getErrorMessage(error),
      });
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Enregistrer" icon={Icon.Check} onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.Description text="Collez vos jetons API ici. Ces champs remplacent les préférences Raycast (indisponibles sur certaines installs Development)." />
      <Form.PasswordField
        id="cloudflareToken"
        title="Jeton Cloudflare"
        placeholder="Cloudflare API Token"
        value={cloudflareToken}
        onChange={setCf}
        info="Permission Zone → Cache Purge. Requis pour « Purger une URL » et les sites Cloudflare."
      />
      <Form.PasswordField
        id="hostingerToken"
        title="Jeton Hostinger"
        placeholder="Hostinger API Token"
        value={hostingerToken}
        onChange={setHi}
        info="hPanel → API. Requis pour purger les sites Hostinger."
      />
    </Form>
  );
}
