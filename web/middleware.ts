import { NextRequest, NextResponse } from "next/server";

/**
 * CORS for the API, so a browser-based client (for example Flutter web) can call it.
 * Native apps (Android, iOS) don't send an Origin header and aren't affected.
 * - Production: only origins listed in CORS_ORIGINS (comma separated).
 * - Development: also allows localhost and private LAN addresses on any port.
 */
const allowList = (process.env.CORS_ORIGINS ?? "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

const devOrigin =
  /^http:\/\/(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+)(:\d+)?$/;

function allowedOrigin(origin: string | null): string | null {
  if (!origin) return null;
  if (allowList.includes(origin)) return origin;
  if (process.env.NODE_ENV !== "production" && devOrigin.test(origin)) return origin;
  return null;
}

function applyCors(res: NextResponse, origin: string) {
  res.headers.set("Access-Control-Allow-Origin", origin);
  res.headers.set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.headers.set("Access-Control-Max-Age", "600");
  res.headers.append("Vary", "Origin");
}

export function middleware(req: NextRequest) {
  const origin = allowedOrigin(req.headers.get("origin"));

  // Answer the browser's preflight without reaching a route.
  if (req.method === "OPTIONS") {
    const res = new NextResponse(null, { status: 204 });
    if (origin) applyCors(res, origin);
    return res;
  }

  const res = NextResponse.next();
  if (origin) applyCors(res, origin);
  return res;
}

export const config = {
  matcher: "/api/:path*",
};
