"use client";

import { useEffect, useRef } from "react";
import { createClient } from "@/lib/supabase/browser";

/** Handles Supabase invite links configured with the implicit token redirect. */
export function AuthFragmentHandler() {
  const started = useRef(false);

  useEffect(() => {
    if (started.current) return;
    const fragment = new URLSearchParams(window.location.hash.slice(1));
    const type = fragment.get("type");
    const accessToken = fragment.get("access_token");
    const refreshToken = fragment.get("refresh_token");
    // Supabase invite links can arrive without a `type` parameter when the
    // dashboard redirects to the project's Site URL. Process only an actual
    // token pair and leave ordinary provider redirects alone.
    if (!accessToken || !refreshToken || (type && type !== "invite" && type !== "recovery")) return;

    started.current = true;
    void (async () => {
      const client = createClient();
      const { data, error } = await client.auth.setSession({ access_token: accessToken, refresh_token: refreshToken });
      if (error || !data.session) {
        window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}`);
        window.location.replace("/login?error=invite_required");
        return;
      }

      // Remove the one-time access token from the address bar and browser history.
      window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}`);
      const destination = type === "recovery" ? "/reset-password" : "/reset-password?next=/platform/setup";
      window.location.replace(destination);
    })();
  }, []);

  return null;
}
