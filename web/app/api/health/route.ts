export const dynamic = "force-dynamic";

export function GET() {
  return Response.json({
    app: "web",
    status: "ok",
    time: new Date().toISOString(),
  });
}
