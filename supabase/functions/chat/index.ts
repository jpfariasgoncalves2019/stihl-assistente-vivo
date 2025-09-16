import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// Configuração
const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const openaiApiKey = Deno.env.get('OPENAI_API_KEY')!;
const openaiModel = Deno.env.get('OPENAI_MODEL') || 'gpt-4o-mini';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ChatRequest {
  message: string;
  channel: 'web' | 'telegram' | 'whatsapp';
  sender: string;
}

interface SearchResult {
  part_code: string;
  description: string;
  price_brl: number;
  model: string;
  rank: number;
}

interface DocFact {
  heading: string;
  item_number: number;
  model_code: string;
  part_code: string;
  part_desc: string;
  page: number;
}

interface ModelSuggestion {
  model_code_std: string;
  category: string;
  similarity_score: number;
}

// Função para criar hash SHA-256
async function hashString(str: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(str);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// Função para extrair códigos de modelo e peça
function extractModelAndPart(message: string): { modelQuery: string; partQuery: string } {
  const normalizedMessage = message.toUpperCase().trim();
  
  // Regex para códigos de modelo (ex: MS250, FS55, 08)
  const modelRegex = /\b([A-Z]{1,4}\s*[0-9][0-9A-Z.]*)\b/g;
  const modelMatches = normalizedMessage.match(modelRegex) || [];
  
  // Normalizar modelos encontrados
  const modelQuery = modelMatches
    .map(m => m.replace(/\s+/g, ''))
    .join(' ') || '';
  
  // Extrair termos de peças (remover códigos de modelo da query)
  let partQuery = normalizedMessage;
  modelMatches.forEach(model => {
    partQuery = partQuery.replace(new RegExp(model.replace(/\s+/g, '\\s*'), 'gi'), '');
  });
  
  // Limpar e normalizar query de peças
  partQuery = partQuery
    .replace(/\b(qual|valor|preço|preco|da|do|de|para|motosserra|rocadeira|roçadeira)\b/gi, '')
    .replace(/\s+/g, ' ')
    .trim();

  console.log(`Extraído - Modelo: "${modelQuery}", Peça: "${partQuery}"`);
  
  return { modelQuery, partQuery };
}

// Função para mascarar PII
function maskPII(text: string): string {
  // Mascarar URLs
  let masked = text.replace(/https?:\/\/[^\s]+/gi, '[url]');
  
  // Mascarar telefones brasileiros
  masked = masked.replace(/(\+55\s?)?(\(?\d{2}\)?\s?)?\d{4,5}[-\s]?\d{4}/g, '[fone]');
  
  return masked;
}

// Função para sanitizar resposta
function sanitizeResponse(text: string): string {
  const forbiddenTerms = /\b(pdf|pdfs|manual|manuais|arquivo|arquivos|link|links|url|download|baixar)\b/gi;
  return text.replace(forbiddenTerms, '[informação técnica]');
}

// Função para carregar prompt ativo
async function loadActivePrompt(): Promise<string> {
  try {
    const { data, error } = await supabase
      .from('attendant_prompts')
      .select('content')
      .eq('is_active', true)
      .eq('role', 'system')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      console.error('Erro ao carregar prompt:', error);
      return 'Você é um assistente especializado em peças STIHL. Responda de forma humanizada e direta.';
    }

    return data?.content || 'Você é um assistente especializado em peças STIHL. Responda de forma humanizada e direta.';
  } catch (error) {
    console.error('Erro ao buscar prompt:', error);
    return 'Você é um assistente especializado em peças STIHL. Responda de forma humanizada e direta.';
  }
}

// Função para buscar no catálogo
async function searchCatalog(modelQuery: string, partQuery: string): Promise<SearchResult[]> {
  try {
    const { data, error } = await supabase.rpc('search_parts', {
      model_q: modelQuery,
      part_q: partQuery,
      limit_n: 5
    });

    if (error) {
      console.error('Erro na busca do catálogo:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Erro ao buscar no catálogo:', error);
    return [];
  }
}

// Função para buscar documentos técnicos
async function searchDocs(modelQuery: string, partQuery: string): Promise<DocFact[]> {
  try {
    const { data, error } = await supabase.rpc('search_docs_secure', {
      model_q: modelQuery,
      part_q: partQuery,
      top_k: 5
    });

    if (error) {
      console.error('Erro na busca de documentos:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Erro ao buscar documentos:', error);
    return [];
  }
}

// Função para sugerir modelos
async function suggestModels(query: string): Promise<ModelSuggestion[]> {
  try {
    const { data, error } = await supabase.rpc('suggest_models', {
      q: query,
      limit_n: 3
    });

    if (error) {
      console.error('Erro ao sugerir modelos:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Erro ao buscar sugestões:', error);
    return [];
  }
}

// Função para construir contexto factual
function buildContext(catalogResults: SearchResult[], docFacts: DocFact[]): string {
  let context = '';

  if (catalogResults.length > 0) {
    context += '\nINFORMAÇÕES DO CATÁLOGO:\n';
    catalogResults.forEach((item, i) => {
      context += `${i + 1}. Código: ${item.part_code}\n`;
      context += `   Descrição: ${item.description}\n`;
      if (item.price_brl) {
        context += `   Preço: R$ ${item.price_brl.toFixed(2).replace('.', ',')}\n`;
      }
      context += `   Modelo: ${item.model}\n\n`;
    });
  }

  if (docFacts.length > 0) {
    context += '\nINFORMAÇÕES TÉCNICAS:\n';
    docFacts.forEach((fact, i) => {
      context += `${i + 1}. ${fact.heading || 'Item'} ${fact.item_number || ''}\n`;
      if (fact.part_code) context += `   Código: ${fact.part_code}\n`;
      if (fact.part_desc) context += `   Descrição: ${fact.part_desc}\n`;
      if (fact.model_code) context += `   Modelo: ${fact.model_code}\n`;
      context += '\n';
    });
  }

  return context;
}

// Função para chamar OpenAI
async function callOpenAI(systemPrompt: string, userMessage: string, context: string): Promise<string> {
  const messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: `${userMessage}\n\n${context}` }
  ];

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: openaiModel,
        messages: messages,
        temperature: 0.2,
        max_tokens: 1000
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const data = await response.json();
    return data.choices[0]?.message?.content || 'Desculpe, não consegui gerar uma resposta adequada.';
  } catch (error) {
    console.error('Erro ao chamar OpenAI:', error);
    return 'Desculpe, ocorreu um erro interno. Nosso atendimento humano pode ajudá-lo melhor.';
  }
}

// Função para log da conversa
async function logConversation(
  channel: string,
  userRefHash: string,
  userMessage: string,
  modelDetected: string,
  partQuery: string,
  catalogEvidence: any,
  techEvidence: any,
  responseText: string,
  tookMs: number,
  error?: string
) {
  try {
    await supabase.from('conversation_logs').insert({
      channel,
      user_ref_hash: userRefHash,
      user_message: maskPII(userMessage),
      model_detected: modelDetected,
      part_query: partQuery,
      catalog_evidence: catalogEvidence,
      tech_evidence: techEvidence,
      response_text: responseText,
      took_ms: tookMs,
      error
    });
  } catch (logError) {
    console.error('Erro ao salvar log:', logError);
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    // Parse request
    const { message, channel, sender }: ChatRequest = await req.json();

    if (!message || !channel || !sender) {
      return new Response(
        JSON.stringify({ error: 'Campos obrigatórios: message, channel, sender' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    console.log(`Nova mensagem [${channel}]: ${message}`);

    // Criar hash do sender para anonimização
    const userRefHash = await hashString(sender);

    // Extrair modelo e peça da mensagem
    const { modelQuery, partQuery } = extractModelAndPart(message);

    // Carregar prompt do sistema
    const systemPrompt = await loadActivePrompt();

    // Buscar dados em paralelo
    const [catalogResults, docFacts] = await Promise.all([
      searchCatalog(modelQuery, partQuery),
      searchDocs(modelQuery, partQuery)
    ]);

    // Se não encontrou nada e não há modelo claro, sugerir modelos
    let modelSuggestions: ModelSuggestion[] = [];
    if (catalogResults.length === 0 && !modelQuery) {
      modelSuggestions = await suggestModels(message);
    }

    // Construir contexto
    let context = buildContext(catalogResults, docFacts);

    // Adicionar sugestões de modelo se necessário
    if (modelSuggestions.length > 0) {
      context += '\nMODELOS SUGERIDOS:\n';
      modelSuggestions.forEach((suggestion, i) => {
        context += `${i + 1}. ${suggestion.model_code_std} (${suggestion.category})\n`;
      });
    }

    // Chamar LLM
    const aiResponse = await callOpenAI(systemPrompt, message, context);

    // Sanitizar resposta
    const sanitizedResponse = sanitizeResponse(aiResponse);

    // Calcular tempo decorrido
    const tookMs = Date.now() - startTime;

    // Preparar evidências para log
    const catalogEvidence = catalogResults.length > 0 ? {
      count: catalogResults.length,
      top_results: catalogResults.slice(0, 3).map(r => ({
        code: r.part_code,
        desc: r.description.substring(0, 100),
        price: r.price_brl
      }))
    } : null;

    const techEvidence = docFacts.length > 0 ? {
      count: docFacts.length,
      top_facts: docFacts.slice(0, 3).map(f => ({
        heading: f.heading,
        item: f.item_number,
        model: f.model_code
      }))
    } : null;

    // Log da conversa
    await logConversation(
      channel,
      userRefHash,
      message,
      modelQuery || 'não detectado',
      partQuery || 'não especificado',
      catalogEvidence,
      techEvidence,
      sanitizedResponse,
      tookMs
    );

    console.log(`Resposta gerada em ${tookMs}ms`);

    // Retornar resposta como texto puro
    return new Response(sanitizedResponse, {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'text/plain; charset=utf-8' 
      }
    });

  } catch (error) {
    console.error('Erro na Edge Function:', error);
    
    const errorMessage = 'Desculpe, ocorreu um erro temporário. Por favor, tente novamente ou entre em contato com nosso atendimento humano para uma assistência personalizada.';
    const tookMs = Date.now() - startTime;
    
    // Log do erro (se possível)
    try {
      const errorData = await req.json();
      const userRefHash = await hashString(errorData.sender || 'unknown');
      
      await logConversation(
        errorData.channel || 'unknown',
        userRefHash,
        errorData.message || 'erro na requisição',
        '',
        '',
        null,
        null,
        errorMessage,
        tookMs,
        error.message
      );
    } catch {
      // Ignore logging errors
    }

    return new Response(errorMessage, {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'text/plain; charset=utf-8' 
      }
    });
  }
});