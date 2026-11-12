import { Prisma, type LmsProvider } from "@prisma/client";
import { prisma } from "@/lib/db";
import { ApiError } from "@/lib/api";

export type ProfileInput = { full_name: string; email: string; student_id?: string };

export function toUserDto(user: { id: string; email: string; fullName: string; studentId: string | null }) {
  return { id: user.id, email: user.email, full_name: user.fullName, student_id: user.studentId };
}

export async function assertEmailFree(email: string) {
  const existing = await prisma.user.findUnique({ where: { email }, select: { id: true } });
  if (existing) throw new ApiError(409, "email_in_use");
}

export async function findConnection(provider: LmsProvider, siteUrl: string, externalUserId: string) {
  return prisma.lmsConnection.findUnique({
    where: { provider_siteUrl_externalUserId: { provider, siteUrl, externalUserId } },
    include: { user: true },
  });
}

/** Creates the user and their first connection in one nested write (one transaction). */
export async function createUserWithConnection(
  profile: ProfileInput,
  connection: { provider: LmsProvider; siteUrl: string; externalUserId: string; externalEmail?: string | null },
) {
  try {
    return await prisma.user.create({
      data: {
        email: profile.email,
        fullName: profile.full_name,
        studentId: profile.student_id ?? null,
        lmsConnections: {
          create: {
            provider: connection.provider,
            siteUrl: connection.siteUrl,
            externalUserId: connection.externalUserId,
            externalEmail: connection.externalEmail ?? null,
          },
        },
      },
    });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      const target = String(err.meta?.target ?? "");
      throw new ApiError(409, target.includes("email") ? "email_in_use" : "account_conflict");
    }
    throw err;
  }
}
