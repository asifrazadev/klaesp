import { ApiError } from "@/lib/api";
import { safeMoodlePost } from "@/lib/net/safe-https";

type TokenBody = { token?: string; error?: string; errorcode?: string };
type SiteInfoBody = {
  userid?: number;
  fullname?: string;
  sitename?: string;
  errorcode?: string;
};

/**
 * Exchanges username and password for a Moodle web service token.
 * Error codes below must be confirmed against the school's Moodle version.
 * SSO-only sites are not reliably detectable here; they show up as invalid credentials.
 */
export async function moodleSignIn(siteUrl: string, username: string, password: string): Promise<string> {
  const { body } = await safeMoodlePost(siteUrl, "/login/token.php", {
    username,
    password,
    service: "moodle_mobile_app",
  });
  const data = body as TokenBody;
  if (data.token) return data.token;

  if (data.errorcode === "enablewsdescription" || data.errorcode === "servicenotavailable") {
    throw new ApiError(403, "moodle_webservice_disabled");
  }
  throw new ApiError(401, "moodle_invalid_credentials");
}

/** Reads the Moodle user ID for a token. Used as the sign-in identity. */
export async function moodleSiteInfo(siteUrl: string, token: string): Promise<{ userid: number }> {
  const { body } = await safeMoodlePost(siteUrl, "/webservice/rest/server.php", {
    wstoken: token,
    wsfunction: "core_webservice_get_site_info",
    moodlewsrestformat: "json",
  });
  const data = body as SiteInfoBody;
  if (typeof data.userid === "number") return { userid: data.userid };
  if (data.errorcode === "invalidtoken") throw new ApiError(401, "moodle_token_invalid");
  throw new ApiError(502, "site_unreachable");
}
