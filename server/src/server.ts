import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { DB_VERSION } from "./schema.js";
import { readPhoto, readText, ReaderError, type ImageType } from "./reader.js";

/**
 * Pronexa AI meal reader. Small on purpose: two POST endpoints and a health check.
 * - No user accounts and no storage: requests are read and forgotten.
 * - Meal text and photos are never logged; only status codes and timings are.
 * - Every input is size-checked before it reaches the model.
 */

const PORT = Number(process.env.PORT ?? 8080);
const MAX_BODY = 2.2 * 1024 * 1024; // a 1.5 MB photo as base64, plus a little
const MAX_TEXT = 280;
const MAX_IMAGE = 1.5 * 1024 * 1024;
const IMAGE_TYPES = new Set<ImageType>(["image/jpeg", "image/png", "image/webp"]);

// Simple per-IP rate limit: 20 requests a minute.
const WINDOW_MS = 60_000;
const LIMIT = 20;
const hits = new Map<string, number[]>();
function allowed(ip: string): boolean {
  const now = Date.now();
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < WINDOW_MS);
  recent.push(now);
  hits.set(ip, recent);
  if (hits.size > 10_000) hits.clear();
  return recent.length <= LIMIT;
}

function send(res: ServerResponse, status: number, body: unknown): void {
  const json = JSON.stringify(body);
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(json),
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
  });
  res.end(json);
}

async function readBody(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of req) {
    size += (chunk as Buffer).length;
    if (size > MAX_BODY) throw new ReaderError("too large", 413);
    chunks.push(chunk as Buffer);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw new ReaderError("invalid json", 400);
  }
}

function field(body: unknown, key: string): unknown {
  return typeof body === "object" && body !== null ? (body as Record<string, unknown>)[key] : undefined;
}

async function handle(req: IncomingMessage, res: ServerResponse): Promise<void> {
  const started = Date.now();
  const path = (req.url ?? "").split("?")[0];
  let status = 200;
  try {
    if (req.method === "GET" && path === "/health") return send(res, 200, { ok: true, dbVersion: DB_VERSION });
    if (req.method !== "POST" || (path !== "/v1/read-text" && path !== "/v1/read-photo")) {
      status = 404;
      return send(res, 404, { error: "not found" });
    }
    if (!(req.headers["content-type"] ?? "").startsWith("application/json")) throw new ReaderError("json only", 415);
    if (!allowed(req.socket.remoteAddress ?? "unknown")) throw new ReaderError("slow down", 429);

    const body = await readBody(req);
    if (path === "/v1/read-text") {
      const text = field(body, "text");
      if (typeof text !== "string" || text.trim().length === 0 || text.length > MAX_TEXT) throw new ReaderError("text must be 1-280 characters", 400);
      return send(res, 200, await readText(text.trim()));
    }
    const image = field(body, "image");
    const mediaType = field(body, "mediaType");
    if (typeof image !== "string" || !/^[A-Za-z0-9+/=]+$/.test(image)) throw new ReaderError("image must be base64", 400);
    if (Buffer.byteLength(image, "base64") > MAX_IMAGE) throw new ReaderError("image too large", 413);
    if (typeof mediaType !== "string" || !IMAGE_TYPES.has(mediaType as ImageType)) throw new ReaderError("unsupported image type", 415);
    return send(res, 200, await readPhoto(image, mediaType as ImageType));
  } catch (error) {
    status = error instanceof ReaderError ? error.status : 500;
    send(res, status, { error: error instanceof ReaderError ? error.message : "server error" });
  } finally {
    // No request content in logs.
    console.log(`${req.method} ${path} ${status} ${Date.now() - started}ms`);
  }
}

if (!process.env.ANTHROPIC_API_KEY && !process.env.ANTHROPIC_AUTH_TOKEN) {
  console.error("Set ANTHROPIC_API_KEY before starting the reader.");
  process.exit(1);
}

createServer((req, res) => void handle(req, res)).listen(PORT, () => console.log(`Pronexa reader on :${PORT} (db ${DB_VERSION})`));
