import { NextResponse } from "next/server";
import { ApiError, errorResponse, parseBody } from "@/lib/api";
import { prisma } from "@/lib/db";
import { requireSession } from "@/lib/session";
import { GOOGLE_ISSUER_URL, verifyGoogleIdToken } from "@/lib/google";
import { findConnection } from "@/lib/accounts";
import { googleConnectSchema } from "@/lib/validation";

export const runtime = "nodejs";

/** Links a Google account to the signed-in user. Never merges with another account. */
export async function POST(req: Request) {
  try {
    const { user } = await requireSession(req);
    const body = await parseBody(req, googleConnectSchema);
    const google = await verifyGoogleIdToken(body.id_token);

    const alreadyMine = await prisma.lmsConnection.findUnique({
      where: { userId_provider: { userId: user.id, provider: "GOOGLE" } },
      select: { id: true },
    });
    if (alreadyMine) throw new ApiError(409, "already_connected");

    const linkedElsewhere = await findConnection("GOOGLE", GOOGLE_ISSUER_URL, google.sub);
    if (linkedElsewhere) throw new ApiError(409, "google_account_linked_elsewhere");

    const connection = await prisma.lmsConnection.create({
      data: {
        userId: user.id,
        provider: "GOOGLE",
        siteUrl: GOOGLE_ISSUER_URL,
        externalUserId: google.sub,
        externalEmail: google.email,
      },
    });
    return NextResponse.json(
      {
        connection: {
          id: connection.id,
          provider: connection.provider,
          external_email: connection.externalEmail,
          connected_at: connection.connectedAt,
        },
      },
      { status: 201 },
    );
  } catch (err) {
    return errorResponse(err);
  }
}
