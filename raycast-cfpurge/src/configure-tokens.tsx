import { popToRoot } from "@raycast/api";

import { TokenSetupForm } from "./lib/token-setup-form";

export default function Command() {
  return <TokenSetupForm onDone={() => void popToRoot()} />;
}
