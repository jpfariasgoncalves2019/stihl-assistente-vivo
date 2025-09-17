// functions/ingest/index.ts
// Deno Edge Function to ingest PDFs in 'tech_docs' bucket
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import OpenAI from "npm:openai";
import { readPdfText } from "https://deno.land/x/pdf/mod.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const openaiKey = Deno.env.get("OPENAI_API_KEY")!;
const OPENAI_EMBED = Deno.env.get("OPENAI_EMBED") ?? "text-embedding-3-small";

const sb = createClient(supabaseUrl, supabaseKey);
const oai = new OpenAI({ apiKey: openaiKey });

async function embed(text: string) {
  const res = await oai.embeddings.create({ input: text, model: OPENAI_EMBED });
  return res.data[0].embedding;
}

function chunk(text: string, size = 1200, overlap = 120) {
  const words = text.split(/\s+/);
  const chunks: string[] = [];
  for (let i=0;i<words.length;i+= (size-overlap)) {
    const slice = words.slice(i, i+size).join(" ").trim();
    if (slice.length > 0) chunks.push(slice);
  }
  return chunks;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Use POST", { status: 405 });
  try {
    const { prefix = "" } = await req.json().catch(() => ({ prefix: "" }));

    // List PDFs
    const { data: files, error } = await sb.storage.from("tech_docs").list(prefix, { limit: 1000 });
    if (error) throw error;
    let ingested = 0;

    for (const f of files ?? []) {
      if (!f.name.toLowerCase().endsWith(".pdf")) continue;
      const path = prefix ? `${prefix}/${f.name}` : f.name;
      const { data: signed } = await sb.storage.from("tech_docs").createSignedUrl(path, 60); // temporary URL
      if (!signed?.signedUrl) continue;

      // Download and parse text (server-side only)
      const res = await fetch(signed.signedUrl);
      const buf = await res.arrayBuffer();
      const bytes = new Uint8Array(buf);
      const text = await readPdfText(bytes);
      const checksum = await crypto.subtle.digest("SHA-256", bytes).then((h)=>Array.from(new Uint8Array(h)).map(b=>b.toString(16).padStart(2,"0")).join(""));
      const pages = text.pages;

      // Upsert doc
      const { data: docRow, error: upErr } = await sb.from("docs").upsert({
        source_path: path, filename: f.name, checksum, page_count: pages.length
      }, { onConflict: "checksum" }).select().single();
      if (upErr) throw upErr;

      // Insert chunks
      for (let p=0; p<pages.length; p++) {
        const pageText = pages[p];
        const parts = chunk(pageText);
        for (let i=0;i<parts.length;i++) {
          const emb = await embed(parts[i]);
          await sb.from("doc_chunks").upsert({
            doc_id: docRow.id, page_number: p+1, chunk_index: i, content: parts[i], embedding: emb
          }, { onConflict: "doc_id,page_number,chunk_index" });
        }
      }
      ingested++;
    }

    return new Response(JSON.stringify({ ok: true, ingested }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});