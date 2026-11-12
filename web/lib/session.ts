import { createHash, randomBytes } from "node:crypto";
import { prisma } from "@/lib/db";
import { ApiError } from "@/lib/api";

const SESSION_DAYS = Number(process.env.SESSION_TTL_DAYS ?? 30);

export function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

/** Creates a session. Only the hash is stored; the raw token is returned once to the app. */
export async function createSession(userId: string) {
  const token = randomBytes(32).toString("base64url");
  const expiresAt = new Date(Date.now() + SESSION_DAYS * 24 * 60 * 60 * 1000);
  await prisma.session.create({
    data: { userId, tokenHash: hashToken(token), expiresAt },
  });
  return { token, expiresAt };
}

/** Resolves the signed-in user from `Authorization: Bearer <token>`, or throws 401. */
export async function requireSession(req: Request) {
  const match = /^Bearer\s+(\S+)$/i.exec(req.headers.get("authorization") ?? "");
  if (!match) throw new ApiError(401, "session_invalid");

  const session = await prisma.session.findUnique({
    where: { tokenHash: hashToken(match[1]) },
    include: { user: true },
  });
  if (!session || session.revokedAt || session.expiresAt <= new Date()) {
    throw new ApiError(401, "session_invalid");
  }
  return { sessionId: session.id, user: session.user };
}
