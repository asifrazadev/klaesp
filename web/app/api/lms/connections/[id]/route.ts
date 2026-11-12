import { NextResponse } from "next/server";
import { ApiError, errorResponse } from "@/lib/api";
import { prisma } from "@/lib/db";
import { requireSession } from "@/lib/session";

export const runtime = "nodejs";

type Params = { params: Promise<{ id: string }> };

/** Removes one connection. The user must keep at least one sign-in identity. */
export async function DELETE(req: Request, { params }: Params) {
  try {
    const { user } = await requireSession(req);
    const { id } = await params;

    const target = await prisma.lmsConnection.findFirst({
      where: { id, userId: user.id },
      select: { id: true },
    });
    if (!target) throw new ApiError(404, "not_found");

    const count = await prisma.lmsConnection.count({ where: { userId: user.id } });
    if (count <= 1) throw new ApiError(409, "last_connection");

    await prisma.lmsConnection.delete({ where: { id: target.id } });
    return NextResponse.json({ ok: true });
  } catch (err) {
    return errorResponse(err);
  }
}
