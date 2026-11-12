import { OAuth2Client } from "google-auth-library";
import { ApiError } from "@/lib/api";

const client = new OAuth2Client();

export const GOOGLE_ISSUER_URL = "https://accounts.google.com";

/** Verifies a Google ID token from the app. Returns the stable account ID (`sub`) and email. */
export async function verifyGoogleIdToken(idToken: string): Promise<{ sub: string; email: string }> {
  const audience = (process.env.GOOGLE_CLIENT_IDS ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (audience.length === 0) {
    throw new Error("GOOGLE_CLIENT_IDS is not configured");
  }

  try {
    const ticket = await client.verifyIdToken({ idToken, audience });
    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email || payload.email_verified !== true) {
      throw new ApiError(401, "google_token_invalid");
    }
    return { sub: payload.sub, email: payload.email.toLowerCase() };
  } catch {
    throw new ApiError(401, "google_token_invalid");
  }
}
