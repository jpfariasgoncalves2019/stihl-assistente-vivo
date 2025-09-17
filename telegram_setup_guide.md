# Guia de Configuração do Bot Telegram - STIHL Assistente

## 1. Criar Bot no Telegram

### Passo 1: Conversar com o BotFather
1. Abra o Telegram e procure por `@BotFather`
2. Inicie uma conversa e digite `/start`
3. Digite `/newbot` para criar um novo bot

### Passo 2: Configurar o Bot
1. **Nome do Bot**: `STIHL Assistente Virtual`
2. **Username do Bot**: `stihl_assistente_bot` (ou similar disponível)
3. **Descrição**: `Assistente virtual especializado em peças e equipamentos STIHL`

### Passo 3: Obter Token
- O BotFather fornecerá um token no formato: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
- **IMPORTANTE**: Guarde este token com segurança!

## 2. Configurar Variáveis de Ambiente

Adicione no arquivo `.env`:

```env
# Token do Bot Telegram (obtido do BotFather)
TELEGRAM_BOT_TOKEN=SEU_TOKEN_AQUI

# Outras variáveis já existentes
SUPABASE_URL=sua_url_supabase
SUPABASE_SERVICE_ROLE_KEY=sua_chave_supabase
OPENAI_API_KEY=sua_chave_openai
OPENAI_MODEL=gpt-4o-mini
```

## 3. Deploy da Edge Function

Execute no terminal:

```bash
# Deploy da função Telegram
supabase functions deploy telegram

# Verificar se foi deployada
supabase functions list
```

## 4. Configurar Webhook

### Obter URL da Edge Function
A URL será algo como:
```
https://SEU_PROJETO.supabase.co/functions/v1/telegram
```

### Configurar Webhook no Telegram
Execute este comando substituindo pelos seus valores:

```bash
curl -X POST "https://api.telegram.org/botSEU_TOKEN/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://SEU_PROJETO.supabase.co/functions/v1/telegram",
    "allowed_updates": ["message"]
  }'
```

### Verificar Webhook
```bash
curl "https://api.telegram.org/botSEU_TOKEN/getWebhookInfo"
```

## 5. Comandos do BotFather (Opcional)

Configure comandos para o bot:

```
/setcommands

start - Iniciar conversa com o assistente
help - Ajuda sobre como usar o bot
catalog - Buscar no catálogo de peças
models - Lista de modelos STIHL
```

## 6. Configurações Adicionais do Bot

### Definir Descrição
```
/setdescription
Assistente virtual especializado em peças e equipamentos STIHL. Consulte preços, códigos e compatibilidade de peças diretamente pelo Telegram.
```

### Definir Sobre
```
/setabouttext
🔧 Assistente STIHL - Especialista em Peças

Tire suas dúvidas sobre:
• Preços de peças
• Códigos de produtos
• Compatibilidade entre modelos
• Especificações técnicas

Desenvolvido com tecnologia de IA para atendimento 24/7.
```

### Definir Foto do Perfil
- Envie uma imagem com logo STIHL ou relacionada a ferramentas

## 7. Teste do Bot

1. Procure pelo seu bot no Telegram usando o username
2. Inicie uma conversa com `/start`
3. Teste com perguntas como:
   - "Qual o preço do carburador da FS55?"
   - "Código da corrente da MS250"
   - "Peças compatíveis com FS38"

## 8. Monitoramento

### Logs da Edge Function
```bash
supabase functions logs telegram --follow
```

### Verificar Webhook Status
```bash
curl "https://api.telegram.org/botSEU_TOKEN/getWebhookInfo"
```

## 9. Solução de Problemas

### Bot não responde
1. Verificar se o webhook está configurado corretamente
2. Verificar logs da Edge Function
3. Verificar se todas as variáveis de ambiente estão configuradas

### Erro de autenticação
1. Verificar se o token do bot está correto
2. Verificar se as chaves do Supabase estão corretas

### Respostas lentas
1. Verificar performance da OpenAI API
2. Verificar conexão com banco de dados

## 10. Segurança

- **Nunca** compartilhe o token do bot
- Use HTTPS sempre
- Monitore logs regularmente
- Implemente rate limiting se necessário

---

## Comandos Úteis de Teste

```bash
# Testar webhook manualmente
curl -X POST "https://SEU_PROJETO.supabase.co/functions/v1/telegram" \
  -H "Content-Type: application/json" \
  -d '{
    "update_id": 123,
    "message": {
      "message_id": 1,
      "from": {
        "id": 12345,
        "is_bot": false,
        "first_name": "Teste"
      },
      "chat": {
        "id": 12345,
        "first_name": "Teste",
        "type": "private"
      },
      "date": 1234567890,
      "text": "Qual o preço do carburador da FS55?"
    }
  }'
```

## Status de Implementação

✅ Edge Function criada  
⏳ Bot configurado no BotFather  
⏳ Webhook configurado  
⏳ Testes realizados  

---

**Próximos passos**: Seguir este guia para configurar o bot e realizar os primeiros testes.
