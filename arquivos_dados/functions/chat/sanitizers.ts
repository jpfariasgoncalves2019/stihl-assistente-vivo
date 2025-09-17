// functions/chat/sanitizers.ts
export function sanitizeAnswer(s: string) {
  if (!s) return s;
  let out = s;

  // Remove links and any mention of pdf/manual
  out = out.replace(/https?:\/\/\S+/gi, "[informação interna]");
  out = out.replace(/\b(pdf|manual|clique|link|ver\s+pdf|ver\s+manual)\b/gi, "");
  out = out.replace(/\s{2,}/g, " ").trim();

  // Enforce BRL formatting hints (leave numbers as-is if already formatted)
  return out;
}