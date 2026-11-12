import { NextResponse } from "next/server";
import { ApiError, errorResponse, parseBody } from "@/lib/api";
import { createSession } from "@/lib/session";
import { normalizeMoodleSiteUrl } from "@/lib/url";
import { moodleSignIn, moodleSiteInfo } from "@/lib/moodle";
import {
  assertEmailFree,
  createUserWithConnection,
  findConnection,
  toUserDto,
} from "@/lib/accounts";
import { moodleSignInSchema } from "@/lib/validation";

export const runtime = "nodejs";

/**
 * Sign in with Moodle. Returning users are matched by Moodle user ID.
 * First sign-in needs a profile; the email must not belong to another account.
 * The Moodle password is used once and never stored. The Moodle token is returned once and never stored.
 */
export async function POST(req: Request) {
  try {
    const body = await parseBody(req, moodleSignInSchema);
    const siteUrl = normalizeMoodleSiteUrl(body.site_url);

    const moodleToken = await moodleSignIn(siteUrl, body.username, body.password);
    const { userid } = await moodleSiteInfo(siteUrl, moodleToken);
    const externalUserId = String(userid);

    const existing = await findConnection("MOODLE", siteUrl, externalUserId);
    if (existing) {
      const session = await createSession(existing.userId);
      return NextResponse.json({
        session_token: session.token,
        expires_at: session.expiresAt,
        moodle_token: moodleToken,
        user: toUserDto(existing.user),
      });
    }

    if (!body.profile) throw new ApiError(404, "no_account");
    await assertEmailFree(body.profile.email);

    const user = await createUserWithConnection(body.profile, {
      provider: "MOODLE",
      siteUrl,
      externalUserId,
    });
    const session = await createSession(user.id);
    return NextResponse.json(
      {
        session_token: session.token,
        expires_at: session.expiresAt,
        moodle_token: moodleToken,
        user: toUserDto(user),
      },
      { status: 201 },
    );
  } catch (err) {
    return errorResponse(err);
  }
}
