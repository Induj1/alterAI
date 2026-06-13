// ALTER — OpenAI proxy Edge Function.
//
// The Flutter client NEVER talks to OpenAI directly and NEVER holds the
// platform key. It calls this function with its Supabase JWT; the function
// authenticates the user, enforces a per-user daily quota, and proxies the
// request using the server-held OPENAI_API_KEY secret.
//
// Optional "bring your own key" (BYOK): if the client sends `byok_key`, that
// key is used instead of the platform key and quota is not consumed.
//
// Deploy:
//   supabase functions deploy openai-chat
//   supabase secrets set OPENAI_API_KEY=sk-...
import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const OPENAI_URL = 'https://api.openai.com/v1/chat/completions';
const DAILY_REQUEST_LIMIT = 200; // per user per day on the platform key
const ALLOWED_MODELS = new Set([
  'gpt-4o-mini',
  'gpt-4o',
  'gpt-4.1-mini',
  'gpt-4.1',
]);

interface ChatRequest {
  messages: Array<Record<string, unknown>>;
  model?: string;
  temperature?: number;
  max_tokens?: number;
  json_mode?: boolean;
  byok_key?: string;
  tools?: unknown;
  tool_choice?: unknown;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function callOpenAI(apiKey: string, payload: unknown): Promise<Response> {
  // One retry on transient errors (429 / 5xx) with a short backoff.
  for (let attempt = 0; attempt < 2; attempt++) {
    const res = await fetch(OPENAI_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });
    if (res.status !== 429 && res.status < 500) return res;
    if (attempt === 0) await new Promise((r) => setTimeout(r, 600));
    else return res;
  }
  // Unreachable, but satisfies the type checker.
  return new Response(null, { status: 500 });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  // --- Authenticate the user from their JWT ---
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Missing authorization header' }, 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser();
  if (authError || !user) {
    return json({ error: 'Invalid or expired session' }, 401);
  }

  // --- Parse and validate the request ---
  let body: ChatRequest;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }
  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return json({ error: 'messages is required' }, 400);
  }

  const model = ALLOWED_MODELS.has(body.model ?? '')
    ? body.model!
    : 'gpt-4o-mini';
  const byok = (body.byok_key ?? '').trim();
  const usingPlatformKey = byok.length === 0;

  // --- Per-user daily quota (only for the platform key) ---
  const admin = createClient(supabaseUrl, serviceKey);
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  if (usingPlatformKey) {
    const { data: usage } = await admin
      .from('ai_usage')
      .select('request_count')
      .eq('user_id', user.id)
      .eq('day', today)
      .maybeSingle();

    const used = usage?.request_count ?? 0;
    if (used >= DAILY_REQUEST_LIMIT) {
      return json(
        {
          error:
            'Daily AI limit reached. Add your own OpenAI key in Settings to continue without limits.',
        },
        429,
      );
    }
  }

  // --- Proxy to OpenAI ---
  const apiKey = usingPlatformKey ? Deno.env.get('OPENAI_API_KEY')! : byok;
  if (!apiKey) {
    return json({ error: 'AI service is not configured.' }, 503);
  }

  const payload: Record<string, unknown> = {
    model,
    messages: body.messages,
    temperature: body.temperature ?? 0.7,
    max_tokens: body.max_tokens ?? 1200,
  };
  if (body.json_mode) {
    payload.response_format = { type: 'json_object' };
  }
  // Agent function-calling: pass tools/tool_choice straight through.
  if (body.tools) {
    payload.tools = body.tools;
    if (body.tool_choice) payload.tool_choice = body.tool_choice;
  }

  const openaiRes = await callOpenAI(apiKey, payload);
  const openaiBody = await openaiRes.json().catch(() => null);

  if (!openaiRes.ok) {
    const msg =
      openaiBody?.error?.message ?? `OpenAI request failed (${openaiRes.status})`;
    return json({ error: msg }, openaiRes.status === 401 ? 502 : openaiRes.status);
  }

  const message = openaiBody?.choices?.[0]?.message ?? {};
  const content: string = message?.content ?? '';
  const toolCalls = message?.tool_calls ?? null;
  const finishReason: string = openaiBody?.choices?.[0]?.finish_reason ?? '';
  const totalTokens: number = openaiBody?.usage?.total_tokens ?? 0;

  // --- Record usage (fire-and-forget, platform key only) ---
  if (usingPlatformKey) {
    await admin.rpc('increment_ai_usage', {
      p_user_id: user.id,
      p_day: today,
      p_tokens: totalTokens,
    });
  }

  return json({
    content,
    tool_calls: toolCalls,
    finish_reason: finishReason,
    model,
    tokens: totalTokens,
  });
});
