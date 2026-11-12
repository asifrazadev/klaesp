import { NextResponse } from "next/server";
import type { ZodType } from "zod";

/** An error with a stable code that the app can act on. Messages never include secrets. */
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message?: string,
  ) {
    super(message ?? code);
  }
}

export function errorResponse(err: unknown): NextResponse {
  if (err instanceof ApiError) {
    return NextResponse.json({ error: err.code }, { status: err.status });
  }
  // Log only the error type. Request bodies and credentials must never reach logs.
  console.error("unhandled_error", err instanceof Error ? err.name : "unknown");
  return NextResponse.json({ error: "internal_error" }, { status: 500 });
}

export async function parseBody<T>(req: Request, schema: ZodType<T, any, any>): Promise<T> {
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    throw new ApiError(400, "invalid_json");
  }
  const parsed = schema.safeParse(raw);
  if (!parsed.success) throw new ApiError(400, "invalid_body");
  return parsed.data;
}
