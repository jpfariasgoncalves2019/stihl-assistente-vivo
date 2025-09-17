import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TelegramMessage {
  message_id: number;
  from: {
    id: number;
    first_name: string;
    username?: string;
  };
  chat: {
    id: number;
    type: string;
  };
  date: number;
  text: string;
}

interface TelegramUpdate {
  update_id: number;
  message?: TelegramMessage;
}

// Função para enviar mensagem via Telegram
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
      parse_mode: 'HTML'
    }),
  });

  if (!response.ok) {
    console.error('Erro ao enviar mensagem:', await response.text());
    throw new Error(`Erro HTTP: ${response.status}`);
  }

  return await response.json();
}

// Função para processar mensagem com OpenAI
async function processWithOpenAI(userMessage: string, openaiApiKey: string): Promise<string> {
  const systemPrompt = `Você é um assistente virtual especializado em peças e equipamentos STIHL. 

INSTRUÇÕES:
- Responda sempre em português brasileiro
- Seja cordial e profissional
- Se perguntarem sobre preços de peças, forneça valores aproximados em reais (R$)
- Se perguntarem sobre códigos de peças, forneça códigos realistas
- Se perguntarem sobre compatibilidade, seja específico
- NUNCA mencione "pdf", "manual", "arquivo", "link" ou "download"
- Mantenha respostas concisas (máximo 200 palavras)

Responda à pergunta do usuário sobre equipamentos STIHL.`;

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage }
        ],
        max_tokens: 300,
        temperature: 0.7,
      }),
    });

    if (!response.ok) {
      console.error('Erro OpenAI:', await response.text());
      return 'Desculpe, estou com dificuldades técnicas no momento. Tente novamente em alguns minutos.';
    }

    const data = await response.json();
    return data.choices[0]?.message?.content || 'Desculpe, não consegui processar sua pergunta.';
  } catch (error) {
    console.error('Erro ao chamar OpenAI:', error);
    return 'Desculpe, ocorreu um erro interno. Nossa equipe técnica pode ajudá-lo diretamente.';
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🤖 Webhook Telegram recebido:', req.method);
    
    // Obter variáveis de ambiente
    const botToken = Deno.env.get('TELEGRAM_BOT_TOKEN');
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY');

    console.log('📋 Variáveis:', {
      botToken: !!botToken,
      openaiApiKey: !!openaiApiKey
    });

    if (!botToken) {
      console.error('❌ TELEGRAM_BOT_TOKEN não configurado');
      return new Response('Bot token não configurado', { 
        status: 500,
        headers: corsHeaders 
      });
    }

    if (!openaiApiKey) {
      console.error('❌ OPENAI_API_KEY não configurado');
      return new Response('OpenAI key não configurada', { 
        status: 500,
        headers: corsHeaders 
      });
    }

    // Parse do webhook
    const update: TelegramUpdate = await req.json();
    console.log('📨 Update recebido:', JSON.stringify(update, null, 2));

    // Verificar se é uma mensagem válida
    if (!update.message || !update.message.text) {
      console.log('⚠️ Mensagem inválida ou sem texto');
      return new Response('OK', { 
        status: 200,
        headers: corsHeaders 
      });
    }

    const message = update.message;
    const chatId = message.chat.id;
    const userMessage = message.text;
    const userName = message.from.first_name;

    console.log(`👤 Mensagem de ${userName} (${chatId}): ${userMessage}`);

    // Processar com OpenAI
    console.log('🧠 Processando com OpenAI...');
    const aiResponse = await processWithOpenAI(userMessage, openaiApiKey);
    
    console.log('✅ Resposta da IA:', aiResponse);

    // Enviar resposta
    console.log('📤 Enviando resposta...');
    await sendTelegramMessage(chatId, aiResponse, botToken);
    
    console.log('✅ Resposta enviada com sucesso!');

    return new Response('OK', { 
      status: 200,
      headers: corsHeaders 
    });

  } catch (error) {
    console.error('❌ Erro no webhook:', error);
    
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
})
