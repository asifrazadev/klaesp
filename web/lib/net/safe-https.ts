import { lookup } from "node:dns/promises";
import { request } from "node:https";
import { isIP } from "node:net";
import { ApiError } from "@/lib/api";

const TIMEOUT_MS = 15_000;
const MAX_RESPONSE_BYTES = 256 * 1024;

/** True for addresses a student's Moodle URL must never reach (SSRF). Fails closed. */
export function isBlockedAddress(address: string): boolean {
  const version = isIP(address);

  if (version === 4) {
    const [a, b] = address.split(".").map(Number);
    return (
      a === 0 ||                          // 0.0.0.0/8
      a === 10 ||                         // private
      a === 127 ||                        // loopback
      (a === 100 && b >= 64 && b <= 127) || // carrier-grade NAT
      (a === 169 && b === 254) ||         // link-local and cloud metadata
      (a === 172 && b >= 16 && b <= 31) || // private
      (a === 192 && b === 168) ||         // private
      (a === 192 && b === 0) ||           // IETF protocol assignments
      (a === 198 && (b === 18 || b === 19)) || // benchmarking
      a >= 224                            // multicast and reserved
    );
  }

  if (version === 6) {
    const lower = address.toLowerCase();
    if (lower === "::" || lower === "::1") return true;
    if (lower.startsWith("fc") || lower.startsWith("fd")) return true; // unique local
    if (/^fe[89ab]/.test(lower)) return true;                          // link-local
    if (lower.startsWith("ff")) return true;                           // multicast
    if (lower.startsWith("::ffff:")) return isBlockedAddress(lower.slice(7)); // IPv4-mapped
    return false;
  }

  return true; // not an IP address: fail closed
}

/**
 * POSTs a form to a Moodle HTTPS endpoint.
 * - Resolves the host once, rejects if any resolved address is blocked.
 * - Connects to the checked address, so DNS rebinding cannot swap it afterwards.
 * - Does not follow redirects. Enforces a timeout and a response size limit.
 * Credentials and tokens travel only in the POST body.
 */
export async function safeMoodlePost(
  siteUrl: string,
  endpoint: string,
  form: Record<string, string>,
): Promise<{ status: number; body: unknown }> {
  const base = new URL(siteUrl);
  if (base.protocol !== "https:") throw new ApiError(400, "invalid_site_url");

  const addresses = await lookup(base.hostname, { all: true, verbatim: true }).catch(() => []);
  if (addresses.length === 0 || addresses.some((a) => isBlockedAddress(a.address))) {
    throw new ApiError(400, "invalid_site_url");
  }
  const pinned = addresses[0];

  const payload = new URLSearchParams(form).toString();
  const path = `${base.pathname.replace(/\/+$/, "")}${endpoint}`;

  return new Promise((resolve, reject) => {
    const req = request(
      {
        hostname: base.hostname,
        port: 443,
        path,
        method: "POST",
        timeout: TIMEOUT_MS,
        servername: base.hostname,
        headers: {
          "content-type": "application/x-www-form-urlencoded",
          "content-length": Buffer.byteLength(payload),
          accept: "application/json",
        },
        // Pin the connection to the address that passed the check.
        // Node may ask for either a single address or an array, depending on options.all.
        lookup: (_host: string, options: { all?: boolean }, callback: any) => {
          if (options?.all) callback(null, [{ address: pinned.address, family: pinned.family }]);
          else callback(null, pinned.address, pinned.family);
        },
      },
      (res) => {
        if (res.statusCode !== undefined && res.statusCode >= 300) {
          res.resume();
          return reject(new ApiError(502, "site_unreachable"));
        }
        const chunks: Buffer[] = [];
        let size = 0;
        res.on("data", (chunk: Buffer) => {
          size += chunk.length;
          if (size > MAX_RESPONSE_BYTES) {
            req.destroy();
            return reject(new ApiError(502, "site_unreachable"));
          }
          chunks.push(chunk);
        });
        res.on("end", () => {
          try {
            resolve({
              status: res.statusCode ?? 0,
              body: JSON.parse(Buffer.concat(chunks).toString("utf8")),
            });
          } catch {
            reject(new ApiError(502, "site_unreachable"));
          }
        });
      },
    );

    req.on("timeout", () => req.destroy(new Error("timeout")));
    req.on("error", () => reject(new ApiError(502, "site_unreachable")));
    req.end(payload);
  });
}
