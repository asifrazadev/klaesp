import { NextResponse } from "next/server";
import { errorResponse } from "@/lib/api";
import { prisma } from "@/lib/db";
import { requireSession } from "@/lib/session";

export const runtime = "nodejs";

/** Revokes the current session only. Other devices stay signed in. */
export async function POST(req: Request) {
  try {
    const { sessionId } = await requireSession(req);
    await prisma.session.update({
      where: { id: sessionId },
      data: { revokedAt: new Date() },
    });
    return NextResponse.json({ ok: true });
  } catch (err) {
    return errorResponse(err);
  }
}
