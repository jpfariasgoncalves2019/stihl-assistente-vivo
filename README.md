# STIHL Assistente Virtual

Assistente humanizado especializado em peças e equipamentos STIHL, construído com Supabase, Edge Functions e tecnologia RAG (Retrieval-Augmented Generation) segura.

## 🎯 Características

- **Humanizado**: Responde como um especialista, nunca como robô
- **Multi-canal**: Suporte para web, Telegram e WhatsApp  
- **RAG Seguro**: Nunca expõe informações técnicas internas (PDFs, links, etc.)
- **Base Completa**: Catálogo de peças + documentos técnicos estruturados
- **Logs Completos**: Rastreamento detalhado com mascaramento de PII
- **Seguro**: RLS ativo, sanitização de respostas, políticas restritivas

## 🏗️ Arquitetura

```
┌─ Web Interface ─┐    ┌─ Telegram Bot ─┐    ┌─ WhatsApp API ─┐
│   React + TS    │    │   Webhook      │    │   Webhook      │
└─────────┬───────┘    └────────┬───────┘    └────────┬───────┘
          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  Supabase Edge Function │
                    │     /chat (Deno/TS)     │
                    └───────────┬────────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
    ┌─────▼─────┐         ┌─────▼─────┐         ┌─────▼─────┐
    │  Catalog  │         │ RAG Docs  │         │ OpenAI    │
    │ Functions │         │ Functions │         │ GPT-4o    │
    └─────┬─────┘         └─────┬─────┘         └───────────┘
          │                     │
    ┌─────▼─────┐         ┌─────▼─────┐
    │ Parts DB  │         │ Doc Facts │
    │ (oficina) │         │ (oficina) │
    └───────────┘         └───────────┘
```

## 🚀 Instalação e Deploy

### 1. Pré-requisitos

- Conta no Supabase
- Node.js 18+ e npm
- Python 3.9+ (para scripts de ingestão)
- Supabase CLI instalado

### 2. Configuração do Banco de Dados

Execute o script SQL completo no SQL Editor do Supabase:

```bash
# No SQL Editor do Supabase, execute:
sql/supabase_setup_consolidated_v3.sql
```

> 📋 **Para setup detalhado do banco:** Consulte [DATABASE_SETUP.md](./DATABASE_SETUP.md) para instruções completas de configuração, migrações e troubleshooting.

### 3. Configuração de Secrets

```bash
# Copiar template de configuração
cp env.local.example env.local

# Editar com suas chaves (ver seção Secrets abaixo)
nano env.local

# Configurar secrets no Supabase
supabase secrets set --env-file ./env.local
```

### 4. Deploy da Edge Function

```bash
# Deploy automático
supabase functions deploy chat

# Ou usando o Makefile
make deploy
```

### 5. Importar Dados do Catálogo

```bash
# Instalar dependências Python
pip install pandas openpyxl psycopg[binary] python-dotenv

# Converter planilha Excel para CSVs
python scripts/xlsx_to_catalog_csv.py "Lista Sugerida.xlsx" --output-dir out_csv

# Importar CSVs no banco (via SQL Editor ou psql):
\copy oficina.models FROM 'out_csv/models.csv' WITH CSV HEADER
\copy oficina.parts FROM 'out_csv/parts.csv' WITH CSV HEADER  
\copy oficina.part_prices FROM 'out_csv/part_prices.csv' WITH CSV HEADER
\copy oficina.part_compat_staging FROM 'out_csv/part_compat.csv' WITH CSV HEADER

# Aplicar compatibilidades
SELECT oficina.apply_part_compat_staging();
```

### 6. Ingestão de PDFs (Opcional)

```bash
# Instalar dependências adicionais
pip install pymupdf supabase

# Processar PDFs de vistas explodidas
python scripts/ingest_pdfs_secure.py \
    --pdfs ./pdfs \
    --bucket manuals \
    --upload \
    --replace \
    --upsert-parts \
    --link-compat
```

### 7. Verificação Final

```bash
# Executar health check
make health

# Ou diretamente:
psql $SUPABASE_DB_URL -f sql/HEALTHCHECK.sql

# Teste rápido da API
curl -X POST "https://<PROJECT>.functions.supabase.co/chat" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message":"qual o valor do carburador da FS55?","channel":"web","sender":"test"}'
```

## 🔑 Secrets Necessários

Configure no arquivo `env.local`:

```env
# Supabase (obter no Dashboard)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Database (para scripts Python)
SUPABASE_DB_URL=postgresql://postgres:password@host:5432/postgres

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini

# Telegram (opcional)
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11

# WhatsApp (opcional)  
WHATSAPP_ACCESS_TOKEN=your_token
WHATSAPP_PHONE_NUMBER_ID=your_phone_id
```

## 📊 Estrutura de Dados

### Schema `oficina` (Catálogo)

- **models**: Modelos STIHL (MS250, FS55, etc.)
- **parts**: Catálogo de peças com descrições
- **part_prices**: Preços por lista (padrão: 'sugerida') 
- **part_compat**: Compatibilidade peças ↔ modelos
- **part_aliases**: Sinônimos para busca ("anel de trava" → "anel de retenção")
- **model_aliases**: Aliases de modelos ("08" → "MS08")

### Schema `oficina` (RAG Seguro)

- **docs**: Metadados dos PDFs técnicos
- **doc_chunks**: Chunks vetorizados (embeddings)
- **doc_facts**: **Fatos estruturados extraídos** (nunca texto bruto)

### Schema `public` (Sistema)

- **attendant_prompts**: Prompts do sistema (versionados)
- **conversation_logs**: Logs com PII mascarado

## 🔍 Exemplos de Uso

### Interface Web
```
Usuário: "Qual o valor do carburador da FS55?"
Assistente: "O valor do carburador da Roçadeira FS55 é R$ 128,91
            Descrição: Carburador 4228/15
            Código: 1108-120-0613  
            Compatíveis: FS38/55/55R"
```

### API REST
```bash
curl -X POST "https://your-project.functions.supabase.co/chat" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "preciso da corrente da MS250", 
    "channel": "whatsapp",
    "sender": "+5511999999999"
  }'
```

## 🧪 Testes

Execute os testes de aceitação:

```bash
# Teste 1: Carburador MS08
curl -s -X POST "$CHAT_URL" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message":"Qual o valor do carburador da MS 08?","channel":"web","sender":"test"}' \
  | grep -q "R\$" && echo "✅ PASS" || echo "❌ FAIL"

# Teste 2: Múltiplas opções (FS80)  
curl -s -X POST "$CHAT_URL" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message":"Qual valor da roçadeira FS80?","channel":"web","sender":"test"}' \
  | grep -q "Código:" && echo "✅ PASS" || echo "❌ FAIL"

# Teste 3: Sanitização (não deve conter termos proibidos)
curl -s -X POST "$CHAT_URL" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json"  \
  -d '{"message":"onde baixar manual da MS250?","channel":"web","sender":"test"}' \
  | grep -qv -E "(pdf|manual|download|link)" && echo "✅ PASS" || echo "❌ FAIL"
```

## 🔧 Makefile

```bash
# Comandos disponíveis
make secrets    # Listar secrets configurados
make dev        # Servir Edge Function localmente  
make deploy     # Deploy para produção
make logs       # Ver logs da Edge Function
make health     # Executar health check
make test       # Executar testes de aceitação

# Ingestão de dados
make ingest-pdfs DIR=./pdfs        # Processar PDFs
make import-catalog FILE=lista.xlsx # Importar catálogo Excel
```

## 📈 Monitoramento

### Logs de Conversas

```sql
-- Conversas recentes
SELECT created_at, channel, model_detected, part_query, took_ms
FROM public.conversation_logs 
ORDER BY created_at DESC LIMIT 10;

-- Performance por canal
SELECT channel, 
       AVG(took_ms) as avg_response_time,
       COUNT(*) as total_conversations
FROM public.conversation_logs 
WHERE created_at > now() - interval '24 hours'
GROUP BY channel;
```

### Dashboard Supabase

- **Edge Function Logs**: Monitorar erros e performance
- **Database**: Verificar RLS e políticas  
- **Storage**: Uso do bucket `manuals`
- **Auth**: Usuários ativos (se aplicável)

## 🔄 Operação e Manutenção

### Atualizar Prompt

```sql
-- Desativar prompt atual
UPDATE public.attendant_prompts SET is_active = false;

-- Inserir novo prompt
INSERT INTO public.attendant_prompts (role, content, version, is_active)
VALUES ('system', 'Novo prompt...', '1.1', true);
```

### Enriquecer Aliases

```sql
-- Adicionar novos aliases baseados nos logs
INSERT INTO oficina.part_aliases (alias, canonical, weight)
VALUES ('termo_encontrado_nos_logs', 'termo_canonico', 1.0);

-- Ver termos mais buscados
SELECT part_query, COUNT(*) 
FROM public.conversation_logs 
WHERE part_query IS NOT NULL AND part_query != ''
GROUP BY part_query 
ORDER BY COUNT(*) DESC LIMIT 20;
```

### Reingestão de PDFs

```bash
# Substituir dados existentes
python scripts/ingest_pdfs_secure.py \
    --pdfs ./new_pdfs \
    --replace \
    --upsert-parts \
    --link-compat
```

## 🚨 Troubleshooting

### Função não responde
```bash
# Verificar logs
supabase functions logs chat

# Testar localmente
supabase functions serve chat --no-verify-jwt
```

### Busca não encontra peças
```sql
-- Verificar índices trigram
SELECT schemaname, tablename, indexname 
FROM pg_indexes 
WHERE indexname LIKE '%trgm%';

-- Testar busca diretamente
SELECT * FROM public.search_parts('MS250', 'carburador', 5);
```

### RLS bloqueando acesso
```sql
-- Verificar políticas  
SELECT * FROM pg_policies WHERE schemaname = 'oficina';

-- Testar com service role (deve funcionar)
SET ROLE service_role;
SELECT * FROM oficina.parts LIMIT 1;
```

## 📋 Changelog

### v1.0.0 (Inicial)
- ✅ Sistema completo de chat multi-canal
- ✅ RAG seguro com sanitização  
- ✅ Catálogo normalizado com aliases
- ✅ Ingestão automatizada de PDFs
- ✅ Logs com mascaramento PII
- ✅ RLS e políticas de segurança
- ✅ Health check automatizado

## 🤝 Contribuição

1. **Reportar bugs**: Criar issue com logs relevantes
2. **Novos aliases**: Contribuir via PR com termos comuns  
3. **Melhorias**: Seguir padrões de código TypeScript/Python
4. **Testes**: Sempre adicionar testes para novas funcionalidades

## 📄 Licença

Projeto proprietário STIHL. Uso interno apenas.

---

**🔗 Links Úteis:**
- [Dashboard Supabase](https://supabase.com/dashboard)
- [Documentação Edge Functions](https://supabase.com/docs/guides/functions)  
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Supabase CLI](https://supabase.com/docs/reference/cli)

**📚 Documentação do Projeto:**
- [DATABASE_SETUP.md](./DATABASE_SETUP.md) - Setup detalhado do banco de dados
- [telegram_setup_guide.md](./telegram_setup_guide.md) - Guia de configuração do bot Telegram
- [setup_instructions.md](./setup_instructions.md) - Instruções gerais de instalação