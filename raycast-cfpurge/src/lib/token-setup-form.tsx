import { Action, ActionPanel, Form, Icon, Toast, showToast } from "@raycast/api";
import { useEffect, useState } from "react";

import { getErrorMessage } from "./preferences";
import {
  getCloudflareToken,
  getHostingerToken,
  setCloudflareToken,
  setHostingerToken,
} from "./tokens";

interface FormValues {
  cloudflareToken: string;
  hostingerToken: string;
}

interface Props {
  onDone: () => void;
}

/** Formulaire jetons (LocalStorage) — utilisable en commande dédiée ou en vue embarquée. */
export function TokenSetupForm({ onDone }: Props) {
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
        message: "Stockés dans Raycast (LocalStorage).",
      });
      onDone();
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
          <Action title="Retour" icon={Icon.ArrowLeft} onAction={onDone} />
        </ActionPanel>
      }
    >
      <Form.Description text="Collez vos jetons API. Pas besoin des préférences Raycast (Settings)." />
      <Form.PasswordField
        id="cloudflareToken"
        title="Jeton Cloudflare"
        placeholder="Cloudflare API Token"
        value={cloudflareToken}
        onChange={setCf}
        info="Permission Zone → Cache Purge."
      />
      <Form.PasswordField
        id="hostingerToken"
        title="Jeton Hostinger"
        placeholder="Hostinger API Token"
        value={hostingerToken}
        onChange={setHi}
        info="hPanel → API. Pour les sites Hostinger."
      />
    </Form>
  );
}
