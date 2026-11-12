import { NextResponse } from "next/server";
import { ApiError, errorResponse, parseBody } from "@/lib/api";
import { prisma } from "@/lib/db";
import { requireSession } from "@/lib/session";
import { normalizeMoodleSiteUrl } from "@/lib/url";
import { moodleSignIn, moodleSiteInfo } from "@/lib/moodle";
import { findConnection } from "@/lib/accounts";
import { moodleCredentialsSchema } from "@/lib/validation";

export const runtime = "nodejs";

/** Links a Moodle account to the signed-in user. Never merges with another account. */
export async function POST(req: Request) {
  try {
    const { user } = await requireSession(req);
    const body = await parseBody(req, moodleCredentialsSchema);
    const siteUrl = normalizeMoodleSiteUrl(body.site_url);

    const moodleToken = await moodleSignIn(siteUrl, body.username, body.password);
    const { userid } = await moodleSiteInfo(siteUrl, moodleToken);
    const externalUserId = String(userid);

    const alreadyMine = await prisma.lmsConnection.findUnique({
      where: { userId_provider: { userId: user.id, provider: "MOODLE" } },
      select: { id: true },
    });
    if (alreadyMine) throw new ApiError(409, "already_connected");

    const linkedElsewhere = await findConnection("MOODLE", siteUrl, externalUserId);
    if (linkedElsewhere) throw new ApiError(409, "moodle_account_linked_elsewhere");

    const connection = await prisma.lmsConnection.create({
      data: { userId: user.id, provider: "MOODLE", siteUrl, externalUserId },
    });
    return NextResponse.json(
      {
        connection: {
          id: connection.id,
          provider: connection.provider,
          site_url: connection.siteUrl,
          connected_at: connection.connectedAt,
        },
        moodle_token: moodleToken,
      },
      { status: 201 },
    );
  } catch (err) {
    return errorResponse(err);
  }
}
