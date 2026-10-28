import { useState } from "react";

import { getErrorMessage } from "./preferences";
import { loadSites } from "./sites";
import { Site, SitesNotConfiguredError } from "./types";

interface UseSitesResult {
  sites: Site[];
  errorMessage: string | null;
}

export function useSites(): UseSitesResult {
  const [state] = useState<UseSitesResult>(() => {
    try {
      return { sites: loadSites(), errorMessage: null };
    } catch (error) {
      if (error instanceof SitesNotConfiguredError) {
        return { sites: [], errorMessage: error.message };
      }
      return { sites: [], errorMessage: getErrorMessage(error) };
    }
  });

  return state;
}
