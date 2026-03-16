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
// CORS headers
// ─────────────────────────────────────────

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

// ─────────────────────────────────────────
// Handler
// ─────────────────────────────────────────

export async function handler(event: any) {
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
    const { dreams, type } = body;

    if (!dreams || dreams.trim().length < 20) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: "Not enough dream content" }) };
    }

    // ── Build prompt ────────────────────
    const isMonth = type === "month";
    const prompt = isMonth
      ? `You are a dream analyst. The user has shared their dreams from the past month. Write a beautiful, personal monthly reflection in 3-4 sentences. Identify the dominant themes, recurring symbols, and any emotional arc across the month. Write directly to the user in second person. Be specific, warm, and genuine.\n\n${dreams}`
      : `The following are dream entries from one person over the past week. Write a single paragraph (max 60 words) identifying the recurring themes, symbols, or emotional patterns. Write in second person, warm and observational, not clinical. Start with "This week,"\n\n${dreams}`;

    // ── Call Claude ───────────────────────
    const message = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: isMonth ? 400 : 256,
      messages: [
        {
          role: "user",
          content: prompt,
        },
      ],
    });

    const raw = message.content[0].type === "text" ? message.content[0].text : "";
    const summary = raw.trim();

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ summary }),
    };

  } catch (error) {
    console.error("Week summary error:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Could not generate summary." }),
    };
  }
}
