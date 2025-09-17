import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TelegramMessage {
  message_id: number;
  from: {
    id: number;
    is_bot: boolean;
    first_name: string;
    username?: string;
    language_code?: string;
  };
  chat: {
    id: number;
    first_name: string;
    username?: string;
    type: string;
  };
  date: number;
  text: string;
}

interface TelegramUpdate {
  update_id: number;
  message?: TelegramMessage;
}

interface TelegramWebhookRequest {
  body: TelegramUpdate;
}

// Função para mascarar PII nos logs
function maskPII(text: string): string {
  // Mascarar números de telefone brasileiros
  text = text.replace(/(\+55\s?)?(\(?\d{2}\)?\s?)(\d{4,5})-?(\d{4})/g, '+55 (**) ****-****');
  
  // Mascarar URLs
  text = text.replace(/https?:\/\/[^\s]+/g, '[URL_REMOVIDA]');
  
  return text;
}

// Função para sanitizar resposta da IA
function sanitizeResponse(response: string): string {
  const forbiddenTerms = [
    'pdf', 'PDF', 'manual', 'Manual', 'MANUAL',
    'arquivo', 'Arquivo', 'ARQUIVO',
    'link', 'Link', 'LINK',
    'download', 'Download', 'DOWNLOAD',
    'baixar', 'Baixar', 'BAIXAR',
    'documento', 'Documento', 'DOCUMENTO'
  ];
  
  let sanitized = response;
  
  for (const term of forbiddenTerms) {
    const regex = new RegExp(`\\b${term}\\b`, 'gi');
    sanitized = sanitized.replace(regex, '[INFORMAÇÃO_RESTRITA]');
  }
  
  return sanitized;
}

// Função para enviar mensagem via Telegram Bot API
async function sendTelegramMessage(chatId: number, text: string, botToken: string) {
  const url = `https://api.telegram.org/bot${botToken}/sendMessage`;
  
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      chat_id: chatId,
      text: text,
      parse_mode: 'Markdown',
      disable_web_page_preview: true
    }),
  });

  if (!response.ok) {
    console.error('Erro ao enviar mensagem Telegram:', await response.text());
    throw new Error(`Erro HTTP: ${response.status}`);
  }

  return await response.json();
}

// Função para extrair modelo da mensagem
function extractModel(message: string): string | null {
  const modelPatterns = [
    /\b(MS\s?\d{3})\b/gi,
    /\b(FS\s?\d{2,3})\b/gi,
    /\b(BG\s?\d{2,3})\b/gi,
    /\b(SH\s?\d{2,3})\b/gi,
    /\b(BR\s?\d{3})\b/gi,
    /\b(HT\s?\d{2,3})\b/gi,
    /\b(KM\s?\d{2,3})\b/gi,
    /\b(RE\s?\d{2,3})\b/gi
  ];

  for (const pattern of modelPatterns) {
    const match = message.match(pattern);
    if (match) {
      return match[0].replace(/\s+/g, '').toUpperCase();
    }
  }

  return null;
}

// Função para extrair termos de peças da mensagem
function extractPartTerms(message: string): string[] {
  const partKeywords = [
    'carburador', 'corrente', 'barra', 'filtro', 'vela', 'pistão',
    'cilindro', 'embreagem', 'pinhão', 'tambor', 'mola', 'cabo',
    'punho', 'gatilho', 'acelerador', 'freio', 'óleo', 'combustível',
    'ar', 'escape', 'silencioso', 'protetor', 'guia', 'tensor'
  ];

  const foundTerms: string[] = [];
  const messageLower = message.toLowerCase();

  for (const keyword of partKeywords) {
    if (messageLower.includes(keyword)) {
      foundTerms.push(keyword);
    }
  }

  return foundTerms;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('Telegram webhook recebido:', req.method, req.url)
    
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const telegramBotToken = Deno.env.get('TELEGRAM_BOT_TOKEN')!
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')!
    const openaiModel = Deno.env.get('OPENAI_MODEL') || 'gpt-4o-mini'

    console.log('Variáveis de ambiente:', {
      supabaseUrl: !!supabaseUrl,
      supabaseServiceKey: !!supabaseServiceKey,
      telegramBotToken: !!telegramBotToken,
      openaiApiKey: !!openaiApiKey
    })

    if (!telegramBotToken) {
      console.error('TELEGRAM_BOT_TOKEN não configurado')
      throw new Error('TELEGRAM_BOT_TOKEN não configurado')
    }

    if (!openaiApiKey) {
      console.error('OPENAI_API_KEY não configurado')
      throw new Error('OPENAI_API_KEY não configurado')
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    
    const update: TelegramUpdate = await req.json()
    
    // Verificar se é uma mensagem válida
    if (!update.message || !update.message.text) {
      return new Response('OK', { 
        status: 200,
        headers: corsHeaders 
      })
    }

    const message = update.message
    const chatId = message.chat.id
    const userMessage = message.text
    const userId = message.from.id
    const userName = message.from.first_name || message.from.username || 'Usuário'

    console.log(`Mensagem recebida do Telegram - Chat: ${chatId}, User: ${userId}, Message: ${maskPII(userMessage)}`)

    // Extrair modelo e termos de peças
    const extractedModel = extractModel(userMessage)
    const partTerms = extractPartTerms(userMessage)

    console.log(`Modelo extraído: ${extractedModel}, Termos de peças: ${partTerms.join(', ')}`)

    // Buscar no catálogo de peças
    let catalogContext = ''
    if (extractedModel || partTerms.length > 0) {
      try {
        const { data: catalogData, error: catalogError } = await supabase
          .rpc('search_parts_catalog', {
            search_query: userMessage,
            model_filter: extractedModel,
            limit_results: 5
          })

        if (catalogError) {
          console.error('Erro na busca do catálogo:', catalogError)
        } else if (catalogData && catalogData.length > 0) {
          catalogContext = `\n\nInformações do catálogo STIHL:\n${catalogData.map((item: any) => 
            `• ${item.part_description} (Código: ${item.part_code}) - ${item.formatted_price || 'Preço sob consulta'}\n  Compatível com: ${item.compatible_models || 'Consulte compatibilidade'}`
          ).join('\n')}`
        }
      } catch (error) {
        console.error('Erro ao buscar catálogo:', error)
      }
    }

    // Buscar fatos de documentos
    let documentContext = ''
    try {
      const { data: docData, error: docError } = await supabase
        .rpc('search_document_facts', {
          search_query: userMessage,
          limit_results: 3
        })

      if (docError) {
        console.error('Erro na busca de documentos:', docError)
      } else if (docData && docData.length > 0) {
        documentContext = `\n\nInformações técnicas:\n${docData.map((fact: any) => 
          `• ${fact.fact_text}`
        ).join('\n')}`
      }
    } catch (error) {
      console.error('Erro ao buscar documentos:', error)
    }

    // Construir contexto completo
    const fullContext = `${catalogContext}${documentContext}`.trim()

    // Preparar prompt para OpenAI
    const systemPrompt = `Você é um assistente virtual especializado em peças e equipamentos STIHL. Responda sempre em português brasileiro de forma cordial e profissional.

REGRAS IMPORTANTES:
- NUNCA mencione "pdf", "manual", "arquivo", "link", "download" ou similares
- Use apenas informações do catálogo fornecido
- Formate preços em reais brasileiros (R$ 1.234,56)
- Se não souber algo, diga que pode consultar com a equipe técnica
- Seja conciso mas completo
- Use linguagem humanizada e amigável

Contexto disponível: ${fullContext || 'Nenhuma informação específica encontrada no catálogo.'}

Responda à pergunta do usuário de forma útil e precisa.`

    // Chamar OpenAI
    let aiResponse = 'Desculpe, ocorreu um erro interno. Nossa equipe técnica pode ajudá-lo diretamente.'

    try {
      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${openaiApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: openaiModel,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userMessage }
          ],
          max_tokens: 500,
          temperature: 0.7,
        }),
      })

      if (openaiResponse.ok) {
        const openaiData = await openaiResponse.json()
        aiResponse = openaiData.choices[0]?.message?.content || aiResponse
      } else {
        console.error('Erro na API OpenAI:', await openaiResponse.text())
      }
    } catch (error) {
      console.error('Erro ao chamar OpenAI:', error)
    }

    // Sanitizar resposta
    const sanitizedResponse = sanitizeResponse(aiResponse)

    // Enviar resposta via Telegram
    await sendTelegramMessage(chatId, sanitizedResponse, telegramBotToken)

    // Log da conversa (com PII mascarado)
    try {
      const conversationLog = {
        channel: 'telegram',
        sender_hash: await crypto.subtle.digest('SHA-256', new TextEncoder().encode(`telegram_${userId}`)),
        user_message: maskPII(userMessage),
        ai_response: maskPII(sanitizedResponse),
        extracted_model: extractedModel,
        part_terms: partTerms,
        context_used: fullContext ? 'catalog_and_docs' : 'none',
        timestamp: new Date().toISOString()
      }

      const { error: logError } = await supabase
        .from('oficina.conversation_logs')
        .insert(conversationLog)

      if (logError) {
        console.error('Erro ao salvar log:', logError)
      }
    } catch (error) {
      console.error('Erro ao processar log:', error)
    }

    return new Response('OK', { 
      status: 200,
      headers: corsHeaders 
    })

  } catch (error) {
    console.error('Erro no webhook Telegram:', error)
    
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
