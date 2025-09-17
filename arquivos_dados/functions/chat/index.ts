// functions/chat/index.ts
// Deno Deploy / Supabase Edge Function
// Endpoint: POST /chat
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import OpenAI from "npm:openai";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sanitizeAnswer } from "./sanitizers.ts";

const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
const OPENAI_EMBED = Deno.env.get("OPENAI_EMBED") ?? "text-embedding-3-small";
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const openaiKey = Deno.env.get("OPENAI_API_KEY")!;

const oai = new OpenAI({ apiKey: openaiKey });
const sb = createClient(supabaseUrl, supabaseKey);

type ChatBody = {
  message: string;
  channel?: "web" | "telegram" | "whatsapp";
};

function brCurrency(n?: number) {
  if (n == null || isNaN(n)) return "";
  return new Intl.NumberFormat("pt-BR",{style:"currency",currency:"BRL"}).format(n);
}

function normalize(txt: string) {
  return txt
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g," ")
    .replace(/\s+/g," ")
    .trim();
}

async function findPartsByQuery(message: string) {
  const { data, error } = await sb.rpc("search_parts", { q: message, limit_k: 10 });
  if (error) throw error;
  return data as { part_code: string; description: string; price: number; matched: boolean }[];
}

async function partsForModel(modelCode: string) {
  const { data, error } = await sb.rpc("parts_for_model", { mcode: modelCode, limit_k: 50 });
  if (error) throw error;
  return data as { part_code: string; description: string; price: number }[];
}

async function embed(text: string) {
  const res = await oai.embeddings.create({ input: text, model: OPENAI_EMBED });
  return res.data[0].embedding;
}

async function ragSearch(message: string) {
  const emb = await embed(message);
  const { data, error } = await sb.rpc("match_doc_chunks", { query_embedding: emb, match_count: 5 });
  if (error) throw error;
  // fetch content server-side (NEVER return to client)
  const ids = (data ?? []).map((r: any) => ({ doc_id: r.doc_id, page_number: r.page_number, chunk_index: r.chunk_index }));
  if (ids.length === 0) return [];
  // fetch chunk text with service role
  const { data: chunks } = await sb
    .from("doc_chunks")
    .select("doc_id,page_number,chunk_index,content")
    .in("doc_id", ids.map(i => i.doc_id))
    .limit(5);
  return chunks ?? [];
}

async function buildAnswer(message: string) {
  // 1) quick structured search in parts
  const parts = await findPartsByQuery(message);

  if (parts && parts.length > 0) {
    // if query mentions a specific model too, keep the top alias-matched item
    const top = parts[0];
    const priceFmt = brCurrency(top.price);
    return `Encontrei: ${top.description} | Código: ${top.part_code} | Valor: ${priceFmt}`;
  }

  // 2) try RAG for compatibility/spec info
  const chunks = await ragSearch(message);
  if (chunks.length > 0) {
    const context = chunks.map(c => c.content).join("\n---\n").slice(0, 4000);
    const { data: promptRow } = await sb.from("assistant_prompts").select("persona,instructions").eq("name","Atendente_STIHL").single();
    const system = `${promptRow?.persona ?? ""}\n\n${promptRow?.instructions ?? ""}`;
    const completion = await oai.chat.completions.create({
      model: OPENAI_MODEL,
      temperature: 0.2,
      messages: [
        { role: "system", content: system },
        { role: "user", content: `Pergunta: ${message}\nContexto interno (NÃO EXPOR):\n${context}\n\nResponda de forma humana e objetiva.` }
      ],
    });
    const text = completion.choices[0]?.message?.content?.trim() ?? "Não encontrei.";
    return text;
  }

  // 3) fallback polite answer
  return "Não encontrei essa informação na nossa base. Se puder, me diga o modelo exato e a peça (ex.: “carburador da MS 170”) que eu verifico para você.";
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Use POST", { status: 405 });
    }
    const body = (await req.json()) as ChatBody;
    const message = (body.message ?? "").slice(0, 2000);
    const channel = body.channel ?? "web";

    const answerRaw = await buildAnswer(message);
    const answer = sanitizeAnswer(answerRaw);

    // log (no PII)
    await sb.from("conversation_logs").insert({
      channel, user_message: message, answer_preview: answer.slice(0, 240)
    });

    return new Response(JSON.stringify({ answer }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: "Erro interno" }), { status: 500 });
  }
});