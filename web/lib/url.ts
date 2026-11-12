import { ApiError } from "@/lib/api";

/**
 * Normalises a user-typed Moodle address to `https://host[/path]` with no trailing slash.
 * Rejects anything that is not HTTPS on port 443, or that carries credentials.
 * Address checks (private IPs, DNS) happen later, in lib/net/safe-https.ts.
 */
export function normalizeMoodleSiteUrl(input: string): string {
  let url: URL;
  try {
    url = new URL(input.trim());
  } catch {
    throw new ApiError(400, "invalid_site_url");
  }
  const badPort = url.port !== "" && url.port !== "443";
  if (url.protocol !== "https:" || badPort || url.username || url.password) {
    throw new ApiError(400, "invalid_site_url");
  }
  const path = url.pathname.replace(/\/+$/, "");
  return `https://${url.hostname.toLowerCase()}${path}`;
}
