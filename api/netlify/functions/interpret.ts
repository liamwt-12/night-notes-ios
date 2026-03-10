import Anthropic from "@anthropic-ai/sdk";
import { createClient } from "@supabase/supabase-js";

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

const SURFACE = `You are a thoughtful dream interpreter. Provide a grounded interpretation that:
- Acknowledges the emotional tone
- Connects symbols to real-life meanings
- Asks one reflective question
Keep to 3-4 paragraphs. Be warm, not saccharine.`;

const BENEATH = `You are a Jungian dream analyst. Provide a deeper interpretation that:
- Identifies archetypal patterns (shadow, anima/animus, the Self)
- Explores unconscious communication
- References symbolic meanings
Keep to 4-5 paragraphs. Write with depth and care.`;

export async function handler(event: any) {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Content-Type": "application/json",
  };

  if (event.httpMethod === "OPTIONS") return { statusCode: 200, headers, body: "" };
  if (event.httpMethod !== "POST") return { statusCode: 405, headers, body: '{"error":"Method not allowed"}' };

  try {
    const token = event.headers.authorization?.replace("Bearer ", "");
    if (!token) return { statusCode: 401, headers, body: '{"error":"Unauthorized"}' };

    const { data: { user } } = await supabase.auth.getUser(token);
    if (!user) return { statusCode: 401, headers, body: '{"error":"Invalid token"}' };

    const { dream, mode = "surface" } = JSON.parse(event.body);
    if (!dream || dream.length < 10) return { statusCode: 400, headers, body: '{"error":"Dream too short"}' };

    const { data: canInterpret } = await supabase.rpc("can_interpret_dream", { user_uuid: user.id });
    if (!canInterpret?.allowed) return { statusCode: 403, headers, body: '{"error":"No credits"}' };

    const { data: creditUsed } = await supabase.rpc("use_dream_credit", { user_uuid: user.id });
    if (!creditUsed?.success) return { statusCode: 403, headers, body: '{"error":"Failed to use credit"}' };

    const message = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: mode === "beneath" ? BENEATH : SURFACE,
      messages: [{ role: "user", content: `Here is my dream:\n\n${dream}` }],
    });

    const interpretation = message.content[0].type === "text" ? message.content[0].text : "";

    const { data: saved } = await supabase.from("dreams").insert({
      user_id: user.id, content: dream, interpretation, interpretation_mode: mode, token_used: creditUsed.type === "token"
    }).select().single();

    return { statusCode: 200, headers, body: JSON.stringify({
      interpretation, mode, credit_type: creditUsed.type, dream_id: saved?.id
    })};
  } catch (error) {
    console.error(error);
    return { statusCode: 500, headers, body: '{"error":"Server error"}' };
  }
}
