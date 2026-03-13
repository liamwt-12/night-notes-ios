import Anthropic from "@anthropic-ai/sdk";
import { createClient } from "@supabase/supabase-js";

// ─────────────────────────────────────────
// Clients
// ─────────────────────────────────────────

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
);

// ─────────────────────────────────────────
// System prompt
// ─────────────────────────────────────────

function buildSystemPrompt(dreamerNote: string): string {
  return `You are a quiet, perceptive dream reader. You don't perform — you notice.

Your role is to offer a gentle, honest reading of what a dream might be holding. Not to diagnose, not to alarm, not to overwhelm. Just to reflect what seems to be there.

${dreamerNote}

Write in the second person. Be warm but not effusive. Avoid jargon. No bullet points. No headers. Just flowing prose, 3–4 short paragraphs.

At the end, extract 3–6 recurring symbols or themes as a JSON array of short strings (e.g. ["water", "childhood home", "unknown figure"]). Return them on the final line, prefixed exactly with: SYMBOLS:`;
}

// ─────────────────────────────────────────
// CORS headers
// ─────────────────────────────────────────

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept",
  "Content-Type": "application/json",
};

// ─────────────────────────────────────────
// Handler
// ─────────────────────────────────────────

export async function handler(event: any) {
  // Preflight
  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  if (event.httpMethod !== "POST") {
    return { statusCode: 405, headers, body: JSON.stringify({ error: "Method not allowed" }) };
  }

  try {
    // ── Auth ──────────────────────────────
    const token = event.headers.authorization?.replace("Bearer ", "").trim();
    if (!token) {
      return { statusCode: 401, headers, body: JSON.stringify({ error: "Unauthorized" }) };
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return { statusCode: 401, headers, body: JSON.stringify({ error: "Invalid token" }) };
    }

    // ── Parse body ────────────────────────
    const body = JSON.parse(event.body ?? "{}");
    const { dream, dreamerType = "fragments", dreamerNote = "" } = body;

    if (!dream || dream.trim().length < 10) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: "Dream too short" }) };
    }

    // ── Subscription / free tier check ────
    const { data: profile } = await supabase
      .from("profiles")
      .select("subscription_active, free_interpretations_used")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return { statusCode: 403, headers, body: JSON.stringify({ error: "Profile not found" }) };
    }

    const canInterpret =
      profile.subscription_active || profile.free_interpretations_used < 7;

    if (!canInterpret) {
      return { statusCode: 403, headers, body: JSON.stringify({ error: "No interpretations remaining" }) };
    }

    // ── Check if client wants streaming (SSE) ──
    const wantsStream = event.headers.accept?.includes("text/event-stream");

    // ── Call Claude with streaming ───────
    const stream = anthropic.messages.stream({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: buildSystemPrompt(dreamerNote),
      messages: [
        {
          role: "user",
          content: `Here is my dream:\n\n${dream.trim()}`,
        },
      ],
    });

    let fullText = "";
    const tokens: string[] = [];

    stream.on("text", (text) => {
      fullText += text;
      tokens.push(text);
    });

    await stream.finalMessage();

    // ── Parse symbols from response ───────
    const symbolsMatch = fullText.match(/SYMBOLS:\s*(\[.*?\])/s);
    let symbols: string[] = [];
    if (symbolsMatch) {
      try {
        symbols = JSON.parse(symbolsMatch[1]);
      } catch {
        symbols = [];
      }
    }

    // Clean interpretation — strip the SYMBOLS line
    const interpretation = fullText.replace(/SYMBOLS:.*$/s, "").trim();

    // ── Save to Supabase ──────────────────
    const { data: saved } = await supabase
      .from("dream_entries")
      .insert({
        user_id: user.id,
        raw_text: dream.trim(),
        interpretation,
        dreamer_type: dreamerType,
        symbols: symbols.join(","),
      })
      .select()
      .single();

    // ── Increment free usage if not subscribed ──
    if (!profile.subscription_active) {
      await supabase
        .from("profiles")
        .update({ free_interpretations_used: profile.free_interpretations_used + 1 })
        .eq("id", user.id);
    }

    // ── Return SSE or JSON based on Accept header ──
    if (wantsStream) {
      let sseBody = "";
      for (const token of tokens) {
        sseBody += `data: ${JSON.stringify({ type: "token", text: token })}\n\n`;
      }
      sseBody += `data: ${JSON.stringify({ type: "done", symbols, dreamId: saved?.id ?? null })}\n\n`;

      return {
        statusCode: 200,
        headers: {
          ...headers,
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
        },
        body: sseBody,
      };
    }

    // ── Standard JSON response ────────────
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        interpretation,
        symbols,
        dreamId: saved?.id ?? null,
      }),
    };

  } catch (error) {
    console.error("Interpret error:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Something went quiet. Try again in a moment." }),
    };
  }
}
