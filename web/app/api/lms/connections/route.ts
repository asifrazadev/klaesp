import { NextResponse } from "next/server";
import { errorResponse } from "@/lib/api";
import { prisma } from "@/lib/db";
import { requireSession } from "@/lib/session";

export const runtime = "nodejs";

/** Lists the signed-in user's connections. Identifiers only; no tokens exist on the server. */
export async function GET(req: Request) {
  try {
    const { user } = await requireSession(req);
    const rows = await prisma.lmsConnection.findMany({
      where: { userId: user.id },
      orderBy: { connectedAt: "asc" },
    });
    return NextResponse.json({
      connections: rows.map((c) => ({
        id: c.id,
        provider: c.provider,
        site_url: c.siteUrl,
        external_email: c.externalEmail,
        connected_at: c.connectedAt,
        last_synced_at: c.lastSyncedAt,
      })),
    });
  } catch (err) {
    return errorResponse(err);
  }
}
