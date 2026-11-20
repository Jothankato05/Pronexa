import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { cleanReading, ReadingSchema, SYSTEM_PROMPT, type Reading } from "./schema.js";

// The key comes from the environment (ANTHROPIC_API_KEY); it is never in the app.
const client = new Anthropic({ timeout: 20_000, maxRetries: 2 });

export const MODEL = "claude-opus-5-5";

export type ImageType = "image/jpeg" | "image/png" | "image/webp";

export class ReaderError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

/**
 * One structured-output call. Reading a meal is a simple extraction, so effort
 * is low. The system prompt (rules + food list) is cached across requests.
 */
async function read(content: Anthropic.Beta.BetaContentBlockParam[]): Promise<Reading> {
  let response;
  try {
    response = await client.beta.messages.parse({
      model: MODEL,
      max_tokens: 4000,
      // If a safety check wrongly declines, the API retries on a fallback model in the same call.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
      messages: [{ role: "user", content }],
      output_config: { effort: "low", format: zodOutputFormat(ReadingSchema) },
    });
  } catch (error) {
    if (error instanceof Anthropic.RateLimitError) throw new ReaderError("busy", 503);
    if (error instanceof Anthropic.BadRequestError) throw new ReaderError("bad request", 400);
    if (error instanceof Anthropic.APIError) throw new ReaderError("upstream error", 502);
    throw error;
  }
  // A safety decline or a cut-off answer: let the app fall back to its own reader.
  if (response.stop_reason === "refusal" || response.stop_reason === "max_tokens" || !response.parsed_output) {
    throw new ReaderError("no reading", 502);
  }
  return cleanReading(response.parsed_output);
}

export function readText(text: string): Promise<Reading> {
  return read([{ type: "text", text: `What I ate: ${text}` }]);
}

export function readPhoto(base64: string, mediaType: ImageType): Promise<Reading> {
  return read([
    { type: "image", source: { type: "base64", media_type: mediaType, data: base64 } },
    { type: "text", text: "This is a photo of my meal. Which foods from the list are in it, and about how much?" },
  ]);
}
