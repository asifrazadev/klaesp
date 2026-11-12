import { NextResponse } from "next/server";
import { ApiError, errorResponse, parseBody } from "@/lib/api";
import { createSession } from "@/lib/session";
import { GOOGLE_ISSUER_URL, verifyGoogleIdToken } from "@/lib/google";
import {
  assertEmailFree,
  createUserWithConnection,
  findConnection,
  toUserDto,
} from "@/lib/accounts";
import { googleSignInSchema } from "@/lib/validation";

export const runtime = "nodejs";

/**
 * Sign in with Google. Returning users are matched by the Google account ID (`sub`).
 * Google sign-in does not grant Classroom access; that is a separate grant.
 * Accounts are never merged by email.
 */
export async function POST(req: Request) {
  try {
    const body = await parseBody(req, googleSignInSchema);
    const google = await verifyGoogleIdToken(body.id_token);

    const existing = await findConnection("GOOGLE", GOOGLE_ISSUER_URL, google.sub);
    if (existing) {
      const session = await createSession(existing.userId);
      return NextResponse.json({
        session_token: session.token,
        expires_at: session.expiresAt,
        user: toUserDto(existing.user),
      });
    }

    if (!body.profile) throw new ApiError(404, "no_account");
    await assertEmailFree(body.profile.email);

    const user = await createUserWithConnection(body.profile, {
      provider: "GOOGLE",
      siteUrl: GOOGLE_ISSUER_URL,
      externalUserId: google.sub,
      externalEmail: google.email,
    });
    const session = await createSession(user.id);
    return NextResponse.json(
      {
        session_token: session.token,
        expires_at: session.expiresAt,
        user: toUserDto(user),
      },
      { status: 201 },
    );
  } catch (err) {
    return errorResponse(err);
  }
}
